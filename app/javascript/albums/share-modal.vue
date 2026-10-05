<template>
  <teleport to="#modal-root">
    <div :class="['modal', active ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div
        ref="modalCard"
        class="modal-card"
        role="dialog"
        aria-modal="true"
        aria-label="Share Album"
        tabindex="-1"
      >
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Share Album</p>
        </header>
        <div class="modal-card-body">
          <p class="mb-4">
            Anyone with the link can view this album without signing in. The
            link itself never changes when you switch modes below - only what
            it unlocks.
          </p>
          <label
            v-for="option in SHARE_MODE_OPTIONS"
            :key="option.value"
            class="share-mode-option"
            :class="{ 'is-selected': selectedMode === option.value }"
          >
            <input
              type="radio"
              name="album-share-mode"
              class="is-sr-only"
              :value="option.value"
              v-model="selectedMode"
              @change="applyMode"
            />
            <span class="icon-text">
              <span class="icon"><i :class="option.icon"></i></span>
              <span class="has-text-weight-semibold">{{ option.label }}</span>
            </span>
            <span
              class="is-block share-mode-option-description"
              :class="{ 'has-text-weak': selectedMode !== option.value }"
              >{{ option.description }}</span
            >
          </label>

          <div v-if="selectedMode !== 'off' && shareUrl" class="field has-addons mt-4">
            <div class="control is-expanded">
              <input
                type="text"
                class="input"
                readonly
                :value="shareUrl"
                @focus="$event.target.select()"
              />
            </div>
            <div class="control">
              <button type="button" class="button" @click="copyLink">
                Copy
              </button>
            </div>
          </div>
          <p v-else-if="selectedMode === 'off'" class="help mt-4">
            Pick a mode above to create a link.
          </p>

          <div v-if="selectedMode !== 'off' && shareUrl" class="mt-4">
            <button
              v-if="!confirmingRegenerate"
              type="button"
              class="button is-small is-warning"
              @click="confirmingRegenerate = true"
            >
              Regenerate Link
            </button>
            <template v-else>
              <p class="help mb-2">
                The current link will stop working. Continue?
              </p>
              <div class="buttons">
                <button
                  type="button"
                  class="button is-small is-warning"
                  @click="regenerate"
                >
                  Yes, regenerate
                </button>
                <button
                  type="button"
                  class="button is-small is-info"
                  @click="confirmingRegenerate = false"
                >
                  Cancel
                </button>
              </div>
            </template>
          </div>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button type="button" class="button is-info" @click="close">
            Done
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { useModal } from "@/mixins/use-modal";
import toaster from "@/mixins/toaster";
import { SHARE_MODE_OPTIONS } from "@/shared/album-share-modes";

const props = defineProps({
  active: {
    type: Boolean,
    required: true,
  },
  album: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["setMode", "regenerate", "close"]);

const router = useRouter();

const selectedMode = ref(props.album.shareMode || "off");
const confirmingRegenerate = ref(false);

const modal = useModal({ onClose: () => emit("close") });

watch(
  () => props.active,
  (isActive) => {
    if (isActive) {
      selectedMode.value = props.album.shareMode || "off";
      confirmingRegenerate.value = false;
      modal.open();
    } else if (modal.active.value) {
      modal.close();
    }
  },
  { immediate: true },
);

// Keeps the radio in sync with the server's response, e.g. reverting on error.
watch(
  () => props.album.shareMode,
  (mode) => {
    selectedMode.value = mode || "off";
  },
);

const modalCard = modal.modalCard;

const shareUrl = computed(() => {
  if (!props.album.shareToken) return "";
  const { href } = router.resolve({
    name: "albums-show",
    params: { id: props.album.id },
    query: { share: props.album.shareToken },
  });
  return window.location.origin + href;
});

function applyMode() {
  confirmingRegenerate.value = false;
  emit("setMode", { id: props.album.id, mode: selectedMode.value });
}

async function copyLink() {
  try {
    await navigator.clipboard.writeText(shareUrl.value);
    toaster("Link copied");
  } catch {
    toaster("Couldn't copy the link", "is-danger");
  }
}

function regenerate() {
  confirmingRegenerate.value = false;
  emit("regenerate", { id: props.album.id });
}

function close() {
  modal.close();
}
</script>

<style scoped lang="scss">
// Same treatment as .license-option/.privacy-option in license-modal.vue
// and photo-info.vue.
.share-mode-option {
  display: block;
  border: 1px solid var(--bulma-border);
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-bottom: 0.75rem;
  cursor: pointer;
  transition: border-color 0.15s, background-color 0.15s;

  &:last-child {
    margin-bottom: 0;
  }

  &:hover {
    border-color: var(--bulma-primary);
  }

  &:has(input:focus-visible) {
    outline: 2px solid var(--bulma-link);
    outline-offset: 2px;
  }

  &.is-selected {
    border-color: var(--bulma-primary);
    background-color: hsl(var(--bulma-primary-h), var(--bulma-primary-s), var(--bulma-light-l));
    color: hsl(var(--bulma-primary-h), var(--bulma-primary-s), var(--bulma-primary-light-invert-l));
  }
}

.share-mode-option-description {
  margin-top: 0.25rem;
}
</style>
