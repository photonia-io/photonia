<template>
  <div class="message is-warning">
    <div class="message-body content">
      <p>
        If you accidentally removed a photo from the selection, and want to add
        it back, please
        <router-link :to="{ name: 'photos-deselected' }"
          >see the list of recently deselected photos</router-link
        >.
      </p>
      <p v-if="selectionCount > 1">
        The actions below will be applied to
        <strong>all of the following {{ selectionCount }} photos</strong>.
      </p>
      <p v-else-if="selectionCount === 1">
        The actions below will be applied to
        <strong>the following photo</strong>.
      </p>
      <p v-else-if="selectionCount === 0">You have not selected any photos.</p>
      <div class="buttons">
        <AddToAlbumButton
          :photos="props.photos"
          @add-photos-to-album="addPhotosToAlbum"
          @create-album-with-photos="createAlbumWithPhotos"
        />
        <RemoveFromAlbumButton
          :photos="props.photos"
          @remove-photos-from-album="removePhotosFromAlbum"
        />
        <!-- <AddTagsButton :photos="props.photos" /> -->
        <DeleteButton :photos="props.photos" @delete-photos="deletePhotos" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, inject } from "vue";
import { useSelectionStore } from "@/stores/selection";

import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";

import AddToAlbumButton from "@/shared/buttons/add-to-album.vue";
import RemoveFromAlbumButton from "@/shared/buttons/remove-from-album.vue";
// import AddTagsButton from "@/shared/buttons/add-tags.vue";
import DeleteButton from "@/shared/buttons/delete.vue";
import toaster from "../mixins/toaster";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

const selectionStore = useSelectionStore();

const selectionCount = computed(() => selectionStore.selectedPhotos.length);

const apolloClient = inject("apolloClient");

const {
  mutate: deletePhotos,
  onDone: onDeletePhotosDone,
  onError: onDeletePhotosError,
} = useMutation(
  gql`
    mutation ($ids: [String!]!) {
      deletePhotos(ids: $ids) {
        id
      }
    }
  `
);

onDeletePhotosDone(({ data }) => {
  selectionStore.showRemoveNotification = false;
  selectionStore.clearSelectedPhotos();
  apolloClient.cache.reset();
  toaster("The photos were deleted", "is-success");
});

onDeletePhotosError((error) => {
  // todo console.log(error)
});

// add photos to album

const {
  mutate: addPhotosToAlbum,
  onDone: onAddPhotosToAlbumDone,
  onError: onAddPhotosToAlbumError,
} = useMutation(
  gql`
    mutation ($albumId: String!, $photoIds: [String!]!) {
      addPhotosToAlbum(albumId: $albumId, photoIds: $photoIds) {
        id
      }
    }
  `
);

onAddPhotosToAlbumDone(({ data }) => {
  apolloClient.cache.reset();
  toaster("The photos were added to the album", "is-success");
});

onAddPhotosToAlbumError((error) => {
  // todo console.log(error)
});

// create album

const {
  mutate: createAlbumWithPhotos,
  onDone: onCreateAlbumWithPhotosDone,
  onError: onCreateAlbumWithPhotosError,
} = useMutation(
  gql`
    mutation ($title: String!, $photoIds: [String!]!) {
      createAlbumWithPhotos(title: $title, photoIds: $photoIds) {
        id
      }
    }
  `
);

onCreateAlbumWithPhotosDone(({ data }) => {
  apolloClient.cache.reset();
  toaster("The album was created", "is-success");
});

onCreateAlbumWithPhotosError((error) => {
  // todo console.log(error)
});

// remove photos from album
const {
  mutate: removePhotosFromAlbum,
  onDone: onRemovePhotosFromAlbumDone,
  onError: onRemovePhotosFromAlbumError,
} = useMutation(
  gql`
    mutation ($albumId: String!, $photoIds: [String!]!) {
      removePhotosFromAlbum(albumId: $albumId, photoIds: $photoIds) {
        id
        title
      }
    }
  `
);

onRemovePhotosFromAlbumDone(({ data }) => {
  apolloClient.cache.reset();
  toaster(
    "The photos were removed from the album '" +
      data.removePhotosFromAlbum.title +
      "'",
    "is-success"
  );
});

onRemovePhotosFromAlbumError((error) => {
  // todo console.log(error)
});
</script>
