<template>
  <div class="column is-one-quarter is-relative">
    <router-link v-if="!canSelect" :to="photoRoute">
      <div class="image-wrapper">
        <ItemImage :photo="photo" />
        <div v-if="showCoverTag" class="cover-photo-tag" @click.stop>
          <span class="tag is-info is-light is-small">Cover Photo</span>
        </div>
      </div>
      {{ photo.title }}
    </router-link>
    <template v-else>
      <div
        class="photo-card is-clickable"
        :class="{ 'is-selecting': selectionStore.isSelecting }"
        tabindex="0"
        @click="handleCardClick"
        @pointerdown="onPointerDown"
        @pointermove="onPointerMove"
        @pointerup="onPointerUp"
        @pointercancel="onPointerCancel"
        @contextmenu="onContextMenu"
      >
        <div class="image-wrapper">
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

          <ItemCheckbox :checked="isPhotoSelected" @click.stop="handleCheckboxClick" />

          <!-- Cover Photo tag -->
          <div v-if="showCoverTag" class="cover-photo-tag" @click.stop>
            <span class="tag is-info is-light is-small">Cover Photo</span>
          </div>
        </div>
      </div>
      <router-link :to="photoRoute">
        {{ photo.title }}
      </router-link>
    </template>
  </div>
</template>

<script setup>
/**
 * PhotoItem Component
 * -------------------
 * A single photo in a grid.
 *
 * Selection is implicit: an editable card reveals a checkbox on hover (or
 * long-press on touch); a plain click toggles it once anything is selected
 * or that photo's checkbox is showing, otherwise it navigates. Ctrl/Cmd-click
 * always toggles; shift-click selects a range within the current page.
 *
 * Props:
 * - `photo` (Object, required)
 * - `inAlbum` (Boolean): whether this card is shown inside an album's photo
 *   grid — controls the cover-photo star/tag, not selection.
 * - `canEditAlbum` (Boolean): whether the current user can edit that album.
 * - `albumId` (String): slug of the album this grid belongs to. Distinct
 *   from `inAlbum` — when set, the photo link starts album (J/K) navigation.
 *
 * Emits: `set-cover-photo`.
 */

import { computed } from "vue";
import { useRouter } from "vue-router";

import { useUserStore } from "@/stores/user";
import { useSelectionStore } from "@/stores/selection";
import { useLongPress } from "@/mixins/use-long-press";

import ItemImage from "@/shared/item-image.vue";
import ItemCheckbox from "@/shared/item-checkbox.vue";

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
  albumId: {
    type: String,
    default: null,
    required: false,
  },
});

const emit = defineEmits(["set-cover-photo"]);

const router = useRouter();
const userStore = useUserStore();
const selectionStore = useSelectionStore();

const photoRoute = computed(() => ({
  name: "photos-show",
  params: { id: props.photo.id },
  ...(props.albumId ? { query: { inAlbum: props.albumId } } : {}),
}));

const canSelect = computed(
  () => userStore.signedIn && userStore.uploader && !!props.photo.canEdit,
);

const canSetCover = computed(
  () =>
    props.inAlbum &&
    props.canEditAlbum &&
    userStore.signedIn &&
    userStore.uploader &&
    !!props.photo.canEdit,
);

const showCoverTag = computed(
  () => !!props.photo.isCoverPhoto && userStore.signedIn && props.canEditAlbum,
);

const isPhotoSelected = computed(() => selectionStore.isSelected(props.photo.id));

const handleCardClick = (event) => {
  if (event.shiftKey) {
    selectionStore.selectRange(props.photo.id);
    return;
  }
  if (event.metaKey || event.ctrlKey || selectionStore.isSelecting) {
    selectionStore.toggle(props.photo);
    return;
  }
  router.push(photoRoute.value);
};

const handleCheckboxClick = (event) => {
  if (event.shiftKey) {
    selectionStore.selectRange(props.photo.id);
  } else {
    selectionStore.toggle(props.photo);
  }
};

const { onPointerDown, onPointerMove, onPointerUp, onPointerCancel, onContextMenu } =
  useLongPress(() => selectionStore.toggle(props.photo));
</script>

<style>
.photo-card {
  position: relative;
}

.image-wrapper {
  position: relative;
}

.cover-photo-icon-container {
  position: absolute;
  top: 1.25em;
  /* place to the left of the checkbox (checkbox right offset is 0.75em and width is 1.5em) */
  right: 3em;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.12s ease;
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

/* The checkbox (and, in an album, the cover star) only fade in on hover,
   keyboard focus, or while a selection is active/hinted — so browsing a
   grid with nothing selected shows a clean image. */
.photo-card .item-checkbox-container {
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.12s ease;
}

.photo-card:hover .item-checkbox-container,
.photo-card:focus-within .item-checkbox-container,
.photo-card:hover .cover-photo-icon-container,
.photo-card:focus-within .cover-photo-icon-container,
.photo-card.is-selecting .item-checkbox-container,
.photo-card.is-selecting .cover-photo-icon-container {
  opacity: 1;
  pointer-events: auto;
}

.photo-card:hover .item-checkbox,
.photo-card:focus-within .item-checkbox {
  border-color: #00d1b2;
}
</style>
