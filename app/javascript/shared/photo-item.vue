<template>
  <div class="column is-one-quarter is-relative">
    <div
      v-if="applicationStore.selectionMode || applicationStore.managingAlbum"
    >
      <div class="selectable-item is-clickable" @click="toggleSelection()">
        <ItemImage :photo="photo" />

        <!-- Set Cover Photo icon (to the left of the checkbox) -->
        <div
          class="cover-photo-icon-container"
          v-if="canSetCover"
          :title="
            photo.isCoverPhoto
              ? 'This is the cover photo'
              : 'Set as cover photo'
          "
          @click.stop="!photo.isCoverPhoto && emit('set-cover-photo', photo)"
        >
          <div :class="['cover-photo-icon', { disabled: photo.isCoverPhoto }]">
            <span class="icon is-small">
              <i class="fas fa-star"></i>
            </span>
          </div>
        </div>

        <ItemCheckbox
          v-if="userStore.signedIn && userStore.uploader && photo.canEdit"
          :checked="selected"
        />

        <!-- Cover Photo tag -->
        <div v-if="showCoverTag" class="cover-photo-tag" @click.stop>
          <span class="tag is-info is-light is-small">Cover Photo</span>
        </div>
      </div>
      <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
        {{ photo.title }}
      </router-link>
    </div>
    <router-link v-else :to="{ name: 'photos-show', params: { id: photo.id } }">
      <div class="image-wrapper">
        <ItemImage :photo="photo" />
        <div v-if="showCoverTag" class="cover-photo-tag" @click.stop>
          <span class="tag is-info is-light is-small">Cover Photo</span>
        </div>
      </div>
      {{ photo.title }}
    </router-link>
  </div>
</template>

<script setup>
/**
 * PhotoItem Component
 * -------------------
 * This component represents a single photo item in a grid.
 *
 * Features:
 * - Displays a photo with its title.
 * - Supports selection mode for batch operations.
 * - Includes a clickable checkbox for selecting photos (if the user has permissions).
 *
 * Props:
 * - `photo` (Object, required): The photo object to display.
 * - `inAlbum` (Boolean, optional): Indicates if the photo is displayed in an album. If true, selection is managed via an album-specific selection store.
 *
 * Dependencies:
 * - Uses `ItemImage` to display the photo.
 * - Uses `ItemCheckbox` for selection functionality.
 *
 * Usage:
 * - Used in photo grids or album views.
 * - Example: `<PhotoItem :photo="photo" :inAlbum="true" />`
 */

import { computed } from "vue";

import { useUserStore } from "@/stores/user";
import { useApplicationStore } from "@/stores/application";
import { useSelectionStore } from "@/stores/selection";

import ItemImage from "@/shared/item-image.vue";
import ItemCheckbox from "@/shared/item-checkbox.vue";

const userStore = useUserStore();
const applicationStore = useApplicationStore();
const selectionStore = useSelectionStore();

const emit = defineEmits(["set-cover-photo"]);

const canSetCover = computed(() => {
  return (
    props.inAlbum &&
    applicationStore.managingAlbum &&
    userStore.signedIn &&
    userStore.uploader &&
    props.photo.canEdit
  );
});

const showCoverTag = computed(() => {
  // Show the tag when photo is cover AND either:
  // - managing the album, or
  // - user is signed in and can edit the album (even if not managing)
  return (
    !!props.photo.isCoverPhoto &&
    (applicationStore.managingAlbum ||
      (userStore.signedIn && props.canEditAlbum))
  );
});

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  inAlbum: {
    type: Boolean,
    default: false,
    required: false,
  },
  canEditAlbum: {
    type: Boolean,
    default: false,
    required: false,
  },
});

const selected = computed(() => {
  if (props.inAlbum) {
    return selectionStore.selectedAlbumPhotos.some(
      (photo) => photo.id === props.photo.id,
    );
  } else {
    return selectionStore.selectedPhotos.some(
      (photo) => photo.id === props.photo.id,
    );
  }
});

const toggleSelection = () => {
  if (selected.value) {
    props.inAlbum
      ? selectionStore.removeAlbumPhoto(props.photo)
      : selectionStore.removePhoto(props.photo);
  } else {
    props.inAlbum
      ? selectionStore.addAlbumPhoto(props.photo)
      : selectionStore.addPhoto(props.photo);
  }
};
</script>

<style>
.selectable-item {
  position: relative;
}
.selectable-item:hover .item-checkbox {
  border-color: #00d1b2;
}

.image-wrapper {
  position: relative;
}

.cover-photo-icon-container {
  position: absolute;
  top: 1.25em;
  /* place to the left of the checkbox (checkbox right offset is 0.75em and width is 1.5em) */
  right: 3em;
}

.cover-photo-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1.5em;
  height: 1.5em;
  background-color: #fff;
  border-radius: 3px;
  border: 1px solid #ccc;
  color: #ffdd57; /* Bulma warning yellow for star */
}

.cover-photo-icon:hover {
  border-color: #00d1b2;
  cursor: pointer;
}

.cover-photo-icon.disabled {
  opacity: 0.6;
  cursor: default;
  filter: grayscale(40%);
}

.cover-photo-tag {
  position: absolute;
  right: 0.75em;
  bottom: 0.75em;
  pointer-events: none; /* do not trigger selection toggle */
}
</style>
