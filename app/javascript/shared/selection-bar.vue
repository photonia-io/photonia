<template>
  <div v-if="selectionStore.count > 0" class="selection-bar">
    <div class="container">
      <div class="selection-bar-inner">
        <div class="selection-bar-count">
          <strong>{{ selectionStore.count }}</strong>
          {{ selectionStore.count === 1 ? "photo" : "photos" }} selected
        </div>
        <div class="buttons selection-bar-actions">
          <AddToAlbumButton
            :photos="selectionStore.selected"
            :hide-album-id="context.type === 'albums-show' ? context.param : ''"
            @add-photos-to-album="addPhotosToAlbum"
            @create-album-with-photos="createAlbumWithPhotos"
          />
          <RemoveFromAlbumButton
            :photos="selectionStore.selected"
            @remove-photos-from-album="removePhotosFromAlbum"
          />
          <button
            v-if="context.type === 'albums-show'"
            class="button"
            @click="openRemoveFromThisAlbumModal"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-folder-minus"></i></span>
              <span>Remove From This Album</span>
            </span>
          </button>
          <button
            v-if="context.type === 'albums-show' && selectionStore.count === 1"
            class="button"
            @click="setAsCover"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-star"></i></span>
              <span>Set As Cover</span>
            </span>
          </button>
          <DeleteButton :photos="selectionStore.selected" @delete-photos="deletePhotos" />
          <button class="button" @click="selectAllOnPage">
            <span class="icon-text">
              <span class="icon"><i class="far fa-check-square"></i></span>
              <span>Select All On Page</span>
            </span>
          </button>
          <button class="button" @click="deselectAllOnPage">
            <span class="icon-text">
              <span class="icon"><i class="far fa-square"></i></span>
              <span>Deselect All On Page</span>
            </span>
          </button>
          <button class="button" @click="drawerOpen = true">
            <span class="icon-text">
              <span class="icon"><i class="fas fa-images"></i></span>
              <span>View Selected</span>
            </span>
          </button>
          <ClearSelectionButton />
        </div>
      </div>
    </div>
  </div>

  <SelectionDrawer v-if="drawerOpen" @close="drawerOpen = false" />

  <!-- Remove From This Album confirmation modal -->
  <teleport to="#modal-root">
    <div :class="['modal', removeFromThisAlbumModalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card" ref="removeFromThisAlbumModalCard" tabindex="-1">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Remove From Album</p>
        </header>
        <div class="modal-card-body">
          <p>
            You are about to remove
            <strong>{{ selectionStore.count }}</strong>
            {{ selectionStore.count === 1 ? "photo" : "photos" }}
            from this album. Continue?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="confirmRemoveFromThisAlbum">
              Yes, remove
            </button>
            <button class="button is-info" @click="closeRemoveFromThisAlbumModal">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { inject, ref } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";

import { useSelectionStore } from "@/stores/selection";
import { useSelectionContext } from "@/mixins/use-selection-context";
import { useModal } from "@/mixins/use-modal";
import toaster from "@/mixins/toaster";

import AddToAlbumButton from "@/shared/buttons/add-to-album.vue";
import RemoveFromAlbumButton from "@/shared/buttons/remove-from-album.vue";
import DeleteButton from "@/shared/buttons/delete.vue";
import ClearSelectionButton from "@/shared/buttons/clear-selection.vue";
import SelectionDrawer from "@/shared/selection-drawer.vue";

const selectionStore = useSelectionStore();
const { context } = useSelectionContext();
const apolloClient = inject("apolloClient");

const drawerOpen = ref(false);

// Set only by "Remove From This Album", so the shared onDone handler can tell
// which request it is answering before touching the selection.
const pendingThisAlbumRemoval = ref(null);

// Only editable photos, matching what a card offers a checkbox for — a batch
// containing one unauthorized photo fails as a whole server-side.
const selectAllOnPage = () =>
  selectionStore.addMany(selectionStore.pageCollection.filter((p) => p.canEdit));
const deselectAllOnPage = () => selectionStore.removeMany(selectionStore.pageCollection);

// Add photos to album / create album with photos

const { mutate: addPhotosToAlbum, onDone: onAddPhotosToAlbumDone, onError: onAddPhotosToAlbumError } =
  useMutation(gql`
    mutation ($albumId: String!, $photoIds: [String!]!) {
      addPhotosToAlbum(albumId: $albumId, photoIds: $photoIds) {
        errors
        album {
          id
          title
        }
      }
    }
  `);

onAddPhotosToAlbumDone(({ data }) => {
  const payload = data?.addPhotosToAlbum;
  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg = (payload && payload.errors && payload.errors.join(", ")) || "Unknown error";
    toaster("An error occurred while adding photos to the album: " + msg, "is-danger");
    return;
  }
  apolloClient.cache.reset();
  toaster("The photos were added to the album '" + (payload.album?.title || "") + "'", "is-success");
});

onAddPhotosToAlbumError((error) => {
  toaster("An error occurred while adding photos to the album: " + error.message, "is-danger");
});

const { mutate: createAlbumWithPhotos, onDone: onCreateAlbumWithPhotosDone, onError: onCreateAlbumWithPhotosError } =
  useMutation(gql`
    mutation ($title: String!, $photoIds: [String!]!) {
      createAlbumWithPhotos(title: $title, photoIds: $photoIds) {
        id
      }
    }
  `);

onCreateAlbumWithPhotosDone(() => {
  apolloClient.cache.reset();
  toaster("The album was created", "is-success");
});

onCreateAlbumWithPhotosError((error) => {
  toaster("An error occurred while creating the album: " + error.message, "is-danger");
});

// Remove photos from an album picked from a dropdown (any album, not just the current one)

const { mutate: removePhotosFromAlbum, onDone: onRemovePhotosFromAlbumDone, onError: onRemovePhotosFromAlbumError } =
  useMutation(gql`
    mutation ($albumId: String!, $photoIds: [String!]!) {
      removePhotosFromAlbum(albumId: $albumId, photoIds: $photoIds) {
        errors
        album {
          id
          title
        }
      }
    }
  `);

onRemovePhotosFromAlbumDone(({ data }) => {
  const payload = data?.removePhotosFromAlbum;
  const pending = pendingThisAlbumRemoval.value;
  pendingThisAlbumRemoval.value = null;

  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg = (payload && payload.errors && payload.errors.join(", ")) || "Unknown error";
    toaster("An error occurred while removing photos from the album: " + msg, "is-danger");
    return;
  }
  // Deselect only what a "Remove From This Album" actually removed, and only
  // while still in the context it was fired from. Removing from some other
  // album via the dropdown leaves the selection alone.
  if (
    pending &&
    pending.albumId === payload.album?.id &&
    pending.contextKey === selectionStore.activeContextKey
  ) {
    selectionStore.prune(pending.photoIds);
  }
  apolloClient.cache.reset();
  toaster("The photos were removed from the album '" + (payload.album?.title || "") + "'", "is-success");
});

onRemovePhotosFromAlbumError((error) => {
  pendingThisAlbumRemoval.value = null;
  toaster("An error occurred while removing photos from the album: " + error.message, "is-danger");
});

// Remove from this album (only shown while browsing that album)

const {
  active: removeFromThisAlbumModalActive,
  modalCard: removeFromThisAlbumModalCard,
  open: openRemoveFromThisAlbumModal,
  close: closeRemoveFromThisAlbumModal,
} = useModal();

const confirmRemoveFromThisAlbum = () => {
  const photoIds = selectionStore.selected.map((p) => p.id);
  const albumId = context.value.param;
  if (photoIds.length === 0 || !albumId) return;

  pendingThisAlbumRemoval.value = {
    albumId,
    photoIds,
    contextKey: selectionStore.activeContextKey,
  };
  removePhotosFromAlbum({ albumId, photoIds });
  closeRemoveFromThisAlbumModal();
};

// Set as cover (only shown while browsing that album, with exactly one selected)

const { mutate: setAlbumCoverPhotoMutation, onDone: onSetAlbumCoverPhotoDone, onError: onSetAlbumCoverPhotoError } =
  useMutation(gql`
    mutation ($albumId: String!, $photoId: String!) {
      setAlbumCoverPhoto(albumId: $albumId, photoId: $photoId) {
        errors
        album {
          id
        }
      }
    }
  `);

const setAsCover = () => {
  const photo = selectionStore.selected[0];
  if (!photo || !context.value.param) return;

  setAlbumCoverPhotoMutation({ albumId: context.value.param, photoId: photo.id });
};

onSetAlbumCoverPhotoDone(({ data }) => {
  const payload = data?.setAlbumCoverPhoto;
  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg = (payload && payload.errors && payload.errors.join(", ")) || "Unknown error";
    toaster("Error setting cover photo: " + msg, "is-danger");
    return;
  }
  apolloClient.cache.reset();
  toaster("Cover photo updated", "is-success");
});

onSetAlbumCoverPhotoError((error) => {
  toaster("An error occurred while setting the cover photo: " + error.message, "is-danger");
});

// Delete

const { mutate: deletePhotos, onDone: onDeletePhotosDone, onError: onDeletePhotosError } = useMutation(gql`
  mutation ($ids: [String!]!) {
    deletePhotos(ids: $ids) {
      id
    }
  }
`);

onDeletePhotosDone(({ data }) => {
  const deletedIds = (data?.deletePhotos || []).map((p) => p.id);
  selectionStore.prune(deletedIds);
  apolloClient.cache.reset();
  toaster("The photos were deleted", "is-success");
});

onDeletePhotosError((error) => {
  toaster("An error occurred while deleting the photos: " + error.message, "is-danger");
});
</script>

<style>
.selection-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20; /* above upload.vue's sticky bar (5), below the navbar (30) and modals (40) */
  background-color: var(--bulma-scheme-main);
  border-top: 1px solid var(--bulma-border);
  padding: 0.75rem 0;
  padding-bottom: calc(0.75rem + env(safe-area-inset-bottom, 0px));
}

.selection-bar-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.selection-bar-count {
  white-space: nowrap;
}

.selection-bar-actions {
  margin-bottom: 0;
}
</style>
