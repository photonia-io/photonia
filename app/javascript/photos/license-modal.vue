<template>
  <teleport to="#modal-root">
    <div :class="['modal', active ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div
        ref="modalCard"
        class="modal-card"
        role="dialog"
        aria-modal="true"
        aria-label="Photo License"
        tabindex="-1"
      >
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Photo License</p>
        </header>
        <div class="modal-card-body">
          <p class="mb-4">Choose the license for this photo.</p>
          <label
            v-for="option in LICENSE_OPTIONS"
            :key="option.value"
            class="license-option"
            :class="{ 'is-selected': selectedLicense === option.value }"
          >
            <input
              type="radio"
              name="photo-license"
              class="is-sr-only"
              :value="option.value"
              v-model="selectedLicense"
            />
            <span class="icon-text">
              <span v-if="option.icons?.length" class="license-icons">
                <i
                  v-for="icon in option.icons"
                  :key="icon"
                  :class="icon"
                ></i>
              </span>
              <span class="has-text-weight-semibold">{{ option.label }}</span>
              <span v-if="option.name" class="has-text-weak">{{
                option.name
              }}</span>
            </span>
            <span
              class="is-block license-option-description"
              :class="{ 'has-text-weak': selectedLicense !== option.value }"
              >{{ option.description }}</span
            >
          </label>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-primary" @click="save">
            Set License
          </button>
          <button class="button is-info" @click="close">Cancel</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref, watch } from "vue";
import { useModal } from "../mixins/use-modal.js";
import { LICENSE_OPTIONS, ALL_RIGHTS_RESERVED } from "../shared/licenses.js";

const props = defineProps({
  active: {
    type: Boolean,
    required: true,
  },
  license: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(["save", "close"]);

const selectedLicense = ref(props.license || ALL_RIGHTS_RESERVED);

const modal = useModal({ onClose: () => emit("close") });

watch(
  () => props.active,
  (isActive) => {
    if (isActive) {
      selectedLicense.value = props.license || ALL_RIGHTS_RESERVED;
      modal.open();
    } else if (modal.active.value) {
      modal.close();
    }
  },
  { immediate: true },
);

const modalCard = modal.modalCard;

function save() {
  const current = props.license || ALL_RIGHTS_RESERVED;
  if (selectedLicense.value !== current) {
    emit("save", { license: selectedLicense.value });
  }
  close();
}

function close() {
  modal.close();
}
</script>

<style scoped lang="scss">
// Same treatment as .privacy-option in photo-info.vue, extended with a
// second, lighter line for the license's full name.
.license-option {
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

.license-option-description {
  margin-top: 0.25rem;
}

// Same tightening as photo-info.vue's .license-icons - Bulma's .icon boxes
// each glyph into a fixed 1.5rem square, too wide once several CC badge
// icons sit side by side.
.license-icons {
  display: inline-flex;
  align-items: center;
  height: 1.5rem;
  gap: 0.15em;
}
</style>
