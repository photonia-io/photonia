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
      <span v-if="!loading && !canEdit" class="ml-1">{{
        formatTakenAt(photo.takenAtInfo)
      }}</span>
      <button
        v-if="!loading && canEdit"
        ref="takenAtTriggerButton"
        type="button"
        class="taken-at-trigger is-underlined is-clickable ml-1"
        @click="openTakenAtModal"
      >
        {{ formatTakenAt(photo.takenAtInfo) }}
      </button>
      <span v-if="takenAtChips.length" class="taken-at-chips">
        <span
          v-for="chip in takenAtChips"
          :key="chip.label"
          :title="chip.title"
          class="tag taken-at-chip has-background has-text-weight-bold"
        >
          {{ chip.label }}
        </span>
      </span>
    </div>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-arrow-circle-up"></i></span>
      <span class="has-text-weight-semibold">Date Posted:</span>
      <span v-if="!loading" class="ml-1">{{
        momentFormat(photo.postedAt)
      }}</span>
    </div>
    <div v-if="!loading" class="icon-text">
      <span class="icon"><i class="fas fa-certificate"></i></span>
      <span class="has-text-weight-semibold">License:</span>
      <!-- Keyed to force a full replace - Font Awesome's JS swaps <i> for
           <svg>, so patching individual icons in place leaves stale ones. -->
      <span
        v-if="licenseDisplay.icons?.length"
        :key="licenseDisplay.value"
        class="license-icons"
      >
        <i v-for="icon in licenseDisplay.icons" :key="icon" :class="icon"></i>
      </span>
      <button
        v-if="canEdit"
        ref="licenseTriggerButton"
        type="button"
        class="license-trigger is-underlined is-clickable ml-1"
        @click="openLicenseModal"
      >
        {{ licenseDisplay.label }}
      </button>
      <a
        v-else-if="licenseDisplay.url"
        :href="licenseDisplay.url"
        target="_blank"
        rel="noopener noreferrer"
        class="ml-1"
      >
        {{ licenseDisplay.label }}
      </a>
      <span v-else class="ml-1">{{ licenseDisplay.label }}</span>
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
  <TakenAtModal
    :active="takenAtModalActive"
    :taken-at-info="photo.takenAtInfo"
    :scanned="photo.scanned"
    @save="handleTakenAtSave"
    @reset="handleTakenAtReset"
    @close="handleTakenAtModalClose"
  />
  <LicenseModal
    :active="licenseModalActive"
    :license="photo.license"
    @save="handleLicenseSave"
    @close="handleLicenseModalClose"
  />
</template>

<script setup>
import { computed, ref, toRefs } from "vue";
import { useModal } from "../mixins/use-modal.js";
import PhotoInfobox from "./photo-infobox.vue";
import SidebarHeader from "./sidebar-header.vue";
import TakenAtModal from "./taken-at-modal.vue";
import LicenseModal from "./license-modal.vue";
import { licenseDisplay as getLicenseDisplay } from "../shared/licenses.js";
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

const emit = defineEmits([
  "updatePrivacy",
  "updateTakenAt",
  "resetTakenAt",
  "updateLicense",
]);

const licenseInfoModalActive = ref(false);

const showLicenseInfoModal = () => {
  licenseInfoModalActive.value = true;
};

const format = "dddd, MMMM Do YYYY, H:mm";
function momentFormat(date) {
  return moment(date).format(format);
}

// Builds a local moment from the taken_at components directly, rather than
// parsing an ISO string, so no timezone shifting can happen for a partial date.
function formatTakenAt(info) {
  if (!info) return "";

  const local = moment({
    year: info.year,
    month: (info.month ?? 1) - 1,
    day: info.day ?? 1,
    hour: info.hour ?? 0,
    minute: info.minute ?? 0,
  });

  switch (info.precision) {
    case "year":
      return local.format("YYYY");
    case "month":
      return local.format("MMMM YYYY");
    case "day":
      return local.format("dddd, MMMM Do YYYY");
    default:
      return local.format(format);
  }
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

const selectedPrivacy = ref(photo.value.privacy);
const privacyTriggerButton = ref(null);

const {
  active: modalActive,
  modalCard,
  open: openModal,
  close: closePrivacyModal,
} = useModal({
  onClose: () => privacyTriggerButton.value?.focus(),
});

const openPrivacyModal = () => {
  selectedPrivacy.value = photo.value.privacy;
  openModal();
};

const savePrivacy = () => {
  if (selectedPrivacy.value !== photo.value.privacy) {
    emit("updatePrivacy", {
      id: photo.value.id,
      privacy: selectedPrivacy.value,
    });
  }
  closePrivacyModal();
};

const licenseDisplay = computed(() => getLicenseDisplay(photo.value.license));
const licenseTriggerButton = ref(null);
const licenseModalActive = ref(false);

const openLicenseModal = () => {
  licenseModalActive.value = true;
};

const handleLicenseModalClose = () => {
  licenseModalActive.value = false;
  licenseTriggerButton.value?.focus();
};

const handleLicenseSave = ({ license }) => {
  emit("updateLicense", { id: photo.value.id, license });
};

const takenAtChips = computed(() => {
  const info = photo.value.takenAtInfo;
  const chips = [];
  if (info?.source === "exif") {
    chips.push({
      label: "EXIF",
      title: "This date was read from the photo's EXIF metadata.",
    });
  } else if (info?.source === "user") {
    chips.push({
      label: "User Set",
      title: "This date was entered manually.",
    });
  }
  if (photo.value.scanned) {
    chips.push({
      label: "Scan",
      title: "This is a scan of a print or negative.",
    });
  }
  if (info?.approximate) {
    chips.push({
      label: "Approximate",
      title: "This date is not exact.",
    });
  }
  return chips;
});

const takenAtTriggerButton = ref(null);
const takenAtModalActive = ref(false);

const openTakenAtModal = () => {
  takenAtModalActive.value = true;
};

const handleTakenAtModalClose = () => {
  takenAtModalActive.value = false;
  takenAtTriggerButton.value?.focus();
};

const handleTakenAtSave = (payload) => {
  emit("updateTakenAt", { id: photo.value.id, ...payload });
};

const handleTakenAtReset = () => {
  emit("resetTakenAt", { id: photo.value.id });
};

// Called by show.vue once setPhotoTakenAt/resetPhotoTakenAt actually
// succeed - the modal itself stays open on save/reset so a failed
// mutation doesn't lose what the user entered.
defineExpose({ closeTakenAtModal: handleTakenAtModalClose });
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

.privacy-trigger,
.taken-at-trigger,
.license-trigger {
  background: none;
  border: none;
  padding: 0;
  font: inherit;
  color: inherit;
}

// Bulma's .icon boxes each glyph into a fixed 1.5rem square, which is a lot
// of dead space once several CC badge icons sit side by side - tighten it
// to how CC actually displays its badges, without affecting single icons
// elsewhere in this file.
.license-icons {
  display: inline-flex;
  align-items: center;
  height: 1.5rem;
  margin-left: 0.25rem;
  gap: 0.15em;
}

// A tighter, self-contained gap for chip-to-chip spacing than
// .icon-text's own row-wide gap gives - kept separate so it doesn't
// affect the icon/label/value spacing shared by every other row.
.taken-at-chips {
  display: inline-flex;
  align-items: center;
  gap: 0.15em;
  margin-left: 0.1em;
}

// has-background gives these chips the page's own background (see the
// EXIF chip this was copied from), so the pill itself is invisible - Bulma's
// default 0.75em side padding then reads as bare whitespace around the
// text rather than pill padding. Trim it so the chips sit close together.
.taken-at-chip {
  padding-left: 0.35em;
  padding-right: 0.35em;
}
</style>
