<template>
  <PhotoInfobox>
    <template #header>
      <SidebarHeader icon="fas fa-info-circle" title="Info" />
    </template>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-eye"></i></span>
      <span class="has-text-weight-semibold">Views:</span>
      <span v-if="!loading" class="ml-1">{{ photo.impressionsCount }}</span>
    </div>
    <div v-if="!loading && canEdit" class="icon-text">
      <span class="icon"><i :class="privacyDisplay.icon"></i></span>
      <span class="has-text-weight-semibold">Privacy:</span>
      <button
        ref="privacyTriggerButton"
        type="button"
        class="privacy-trigger is-underlined is-clickable ml-1"
        @click="openPrivacyModal"
      >
        {{ privacyDisplay.label }}
      </button>
    </div>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-camera"></i></span>
      <span class="has-text-weight-semibold">Date Taken:</span>
      <span v-if="!loading" class="ml-1">{{
        momentFormat(photo.takenAt)
      }}</span>
      <span
        v-if="!loading && photo.isTakenAtFromExif"
        class="tag has-background ml-1 has-text-weight-bold"
      >
        EXIF
      </span>
    </div>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-arrow-circle-up"></i></span>
      <span class="has-text-weight-semibold">Date Posted:</span>
      <span v-if="!loading" class="ml-1">{{
        momentFormat(photo.postedAt)
      }}</span>
    </div>
    <div
      v-if="!loading && photo.rekognitionLabelModelVersion !== ''"
      class="icon-text"
    >
      <span class="icon"><i class="fas fa-robot"></i></span>
      <span class="has-text-weight-semibold"
        >Rekognition Label Model Version:</span
      >
      <span class="ml-1">{{ photo.rekognitionLabelModelVersion }}</span>
    </div>
  </PhotoInfobox>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div
        ref="modalCard"
        class="modal-card"
        role="dialog"
        aria-modal="true"
        aria-label="Photo Privacy"
        tabindex="-1"
      >
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Photo Privacy</p>
        </header>
        <div class="modal-card-body">
          <p class="mb-4">Choose who can see this photo.</p>
          <label
            v-for="option in PRIVACY_OPTIONS"
            :key="option.value"
            class="privacy-option"
            :class="{
              'is-selected': selectedPrivacy === option.value,
              'is-option-disabled': option.disabled,
            }"
          >
            <input
              type="radio"
              name="photo-privacy"
              class="is-sr-only"
              :value="option.value"
              v-model="selectedPrivacy"
              :disabled="option.disabled"
            />
            <span class="icon-text">
              <span class="icon"><i :class="option.icon"></i></span>
              <span class="has-text-weight-semibold">{{ option.label }}</span>
            </span>
            <span
              class="is-block privacy-option-description"
              :class="{ 'has-text-weak': selectedPrivacy !== option.value }"
              >{{ option.description }}</span
            >
          </label>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-primary" @click="savePrivacy">
            Set Privacy
          </button>
          <button class="button is-info" @click="closePrivacyModal">
            Cancel
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed, nextTick, onUnmounted, ref, toRefs } from "vue";
import { useApplicationStore } from "../stores/application";
import PhotoInfobox from "./photo-infobox.vue";
import SidebarHeader from "./sidebar-header.vue";
import moment from "moment/min/moment-with-locales";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    required: true,
  },
  canEdit: {
    type: Boolean,
    required: true,
  },
});

const { photo } = toRefs(props);

const emit = defineEmits(["updatePrivacy"]);

const format = "dddd, MMMM Do YYYY, H:mm";
function momentFormat(date) {
  return moment(date).format(format);
}

const PRIVACY_OPTIONS = [
  {
    value: "public",
    icon: "fas fa-globe",
    label: "Public",
    description: "Anyone can see this photo.",
  },
  {
    value: "friends_and_family",
    icon: "fas fa-user-friends",
    label: "Friends & Family",
    description: "Not implemented yet. Behaves the same as Private.",
    disabled: true,
  },
  {
    value: "private",
    icon: "fas fa-lock",
    label: "Private",
    description: "Only you and site admins can see this photo.",
  },
];

const PRIVACY_DISPLAY = Object.fromEntries(
  PRIVACY_OPTIONS.map(({ value, icon, label }) => [value, { icon, label }]),
);

const privacyDisplay = computed(
  () => PRIVACY_DISPLAY[photo.value.privacy] ?? PRIVACY_DISPLAY.public,
);

const applicationStore = useApplicationStore();

const modalActive = ref(false);
const selectedPrivacy = ref(photo.value.privacy);
const privacyTriggerButton = ref(null);
const modalCard = ref(null);

const handleModalKeydown = (event) => {
  if (event.key === "Escape") {
    closePrivacyModal();
  }
};

const openPrivacyModal = () => {
  selectedPrivacy.value = photo.value.privacy;
  modalActive.value = true;
  applicationStore.disableNavigationShortcuts();
  document.addEventListener("keydown", handleModalKeydown);
  nextTick(() => {
    modalCard.value?.focus();
  });
};

const closePrivacyModal = () => {
  modalActive.value = false;
  applicationStore.enableNavigationShortcuts();
  document.removeEventListener("keydown", handleModalKeydown);
  privacyTriggerButton.value?.focus();
};

onUnmounted(() => {
  if (modalActive.value) {
    applicationStore.enableNavigationShortcuts();
    document.removeEventListener("keydown", handleModalKeydown);
  }
});

const savePrivacy = () => {
  if (selectedPrivacy.value !== photo.value.privacy) {
    emit("updatePrivacy", {
      id: photo.value.id,
      privacy: selectedPrivacy.value,
    });
  }
  closePrivacyModal();
};
</script>

<style scoped lang="scss">
.privacy-option {
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

  // Same background/text pairing as .tag/.notification's is-light variant,
  // which is already dark-mode safe (see the is-light fix above).
  &.is-selected {
    border-color: var(--bulma-primary);
    background-color: hsl(var(--bulma-primary-h), var(--bulma-primary-s), var(--bulma-light-l));
    color: hsl(var(--bulma-primary-h), var(--bulma-primary-s), var(--bulma-primary-light-invert-l));
  }

  &.is-option-disabled {
    cursor: not-allowed;
    opacity: 0.6;

    &:hover {
      border-color: var(--bulma-border);
    }
  }
}

.privacy-option-description {
  margin-top: 0.25rem;
}

.privacy-trigger {
  background: none;
  border: none;
  padding: 0;
  font: inherit;
  color: inherit;
}
</style>
