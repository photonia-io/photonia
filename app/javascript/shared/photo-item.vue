<template>
  <div class="column is-one-quarter is-relative">
    <div v-if="applicationStore.selectionMode || applicationStore.editingAlbum">
      <div class="selectable-item is-clickable" @click="toggleSelection()">
        <ItemImage :photo="photo" />
        <ItemCheckbox
          v-if="userStore.signedIn && userStore.uploader && photo.canEdit"
          :checked="selected"
        />
      </div>
      <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
        {{ photo.title }}
      </router-link>
    </div>
    <router-link v-else :to="{ name: 'photos-show', params: { id: photo.id } }">
      <ItemImage :photo="photo" />
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
 * - `inAlbum` (Boolean, optional): Indicates if the photo is displayed in an album.
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
.selectable-item:hover .item-checkbox {
  border-color: #00d1b2;
}
</style>
