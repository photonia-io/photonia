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
      <span
        class="is-underlined is-clickable ml-1"
        @click="openPrivacyModal"
      >
        {{ privacyDisplay.label }}
      </span>
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
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Photo Privacy</p>
        </header>
        <div class="modal-card-body">
          <p class="mb-4">Choose who can see this photo.</p>
          <div class="control">
            <label class="radio is-block mb-3">
              <input
                type="radio"
                name="photo-privacy"
                value="public"
                v-model="selectedPrivacy"
              />
              <span class="icon"><i class="fas fa-globe"></i></span>
              Public
              <span class="has-text-weak is-block ml-5"
                >Anyone can see this photo.</span
              >
            </label>
            <label class="radio is-block mb-3">
              <input
                type="radio"
                name="photo-privacy"
                value="friends_and_family"
                v-model="selectedPrivacy"
                disabled
              />
              <span class="icon"><i class="fas fa-user-friends"></i></span>
              Friends &amp; Family
              <span class="has-text-weak is-block ml-5"
                >Not implemented yet. Behaves the same as Private.</span
              >
            </label>
            <label class="radio is-block">
              <input
                type="radio"
                name="photo-privacy"
                value="private"
                v-model="selectedPrivacy"
              />
              <span class="icon"><i class="fas fa-lock"></i></span>
              Private
              <span class="has-text-weak is-block ml-5"
                >Only you and site admins can see this photo.</span
              >
            </label>
          </div>
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
import { computed, ref, toRefs } from "vue";
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

const PRIVACY_DISPLAY = {
  public: { icon: "fas fa-globe", label: "Public" },
  private: { icon: "fas fa-lock", label: "Private" },
  friends_and_family: { icon: "fas fa-user-friends", label: "Friends & Family" },
};

const privacyDisplay = computed(
  () => PRIVACY_DISPLAY[photo.value.privacy] ?? PRIVACY_DISPLAY.public,
);

const applicationStore = useApplicationStore();

const modalActive = ref(false);
const selectedPrivacy = ref(photo.value.privacy);

const openPrivacyModal = () => {
  selectedPrivacy.value = photo.value.privacy;
  modalActive.value = true;
  applicationStore.disableNavigationShortcuts();
};

const closePrivacyModal = () => {
  modalActive.value = false;
  applicationStore.enableNavigationShortcuts();
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
</script>
