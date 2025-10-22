<template>
  <div class="message is-warning">
    <div class="message-body content">
      <p v-if="selectionCount > 0">
        You have selected <strong>{{ selectionCount }}</strong>
        {{ selectionCount == 1 ? "photo" : "photos" }} in this album.
      </p>
      <p v-else>You have not selected any photos.</p>
      <div class="level">
        <div class="level-left">
          <div class="buttons">
            <AddToAlbumButton
              :photos="selectionStore.selectedAlbumPhotos"
              :hide-album-id="albumId"
              @add-photos-to-album="addPhotosToAlbum"
              @create-album-with-photos="createAlbumWithPhotos"
            />
            <button
              class="button is-danger"
              :disabled="buttonsDisabled"
              @click="$emit('request-remove-from-album')"
            >
              <span class="icon-text">
                <span class="icon"><i class="fas fa-folder-minus"></i></span>
                <span>Remove From Album</span>
              </span>
            </button>
          </div>
        </div>
        <div class="level-right">
          <div class="buttons">
            <button class="button" @click="addAll()">
              <span class="icon-text">
                <span class="icon"><i class="far fa-check-square"></i></span>
                <span>Select All Photos</span>
              </span>
            </button>
            <button class="button" @click="removeAll()">
              <span class="icon-text">
                <span class="icon"><i class="far fa-square"></i></span>
                <span>Deselect All Photos</span>
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, inject } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";

import { useSelectionStore } from "@/stores/selection";
import toaster from "../mixins/toaster";
import AddToAlbumButton from "@/shared/buttons/add-to-album.vue";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
  albumId: {
    type: String,
    required: false,
    default: "",
  },
});

// Emits
defineEmits(["request-remove-from-album"]);

const selectionStore = useSelectionStore();

const selectionCount = computed(
  () => selectionStore.selectedAlbumPhotos.length,
);
const buttonsDisabled = computed(() => selectionCount.value === 0);

const addAll = () => {
  selectionStore.addAlbumPhotos(props.photos);
};

const removeAll = () => {
  selectionStore.removeAlbumPhotos(props.photos);
};

const apolloClient = inject("apolloClient");

// Add photos to album
const {
  mutate: addPhotosToAlbum,
  onDone: onAddPhotosToAlbumDone,
  onError: onAddPhotosToAlbumError,
} = useMutation(gql`
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
    const msg =
      (payload && payload.errors && payload.errors.join(", ")) ||
      "Unknown error";
    toaster(
      "An error occurred while adding photos to the album: " + msg,
      "is-danger",
    );
    return;
  }
  apolloClient.cache.reset();
  toaster(
    "The photos were added to the album '" + (payload.album?.title || "") + "'",
    "is-success",
  );
});

onAddPhotosToAlbumError((error) => {
  toaster(
    "An error occurred while adding photos to the album: " + error.message,
    "is-danger",
  );
});

// Create album with photos
const {
  mutate: createAlbumWithPhotos,
  onDone: onCreateAlbumWithPhotosDone,
  onError: onCreateAlbumWithPhotosError,
} = useMutation(gql`
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
  toaster(
    "An error occurred while creating the album: " + error.message,
    "is-danger",
  );
});
</script>
