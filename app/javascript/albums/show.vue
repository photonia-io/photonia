<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mt-5 mb-0">
        <div class="level-left is-flex-grow-1">
          <div class="level-item is-flex-grow-1 is-justify-content-flex-start">
            <AlbumTitleEditable
              v-if="canEditAlbum"
              :album="album"
              @update-title="updateAlbumTitle"
            />
            <h1 class="title" v-else>
              {{ title }}
            </h1>
          </div>
        </div>
        <div
          class="level-right"
          v-if="userStore.signedIn && userStore.uploader"
        >
          <div class="level-item">
            <button
              class="button is-small"
              v-if="!applicationStore.managingAlbum"
              @click="applicationStore.startManagingAlbum()"
            >
              Manage
            </button>
            <button class="button is-small" v-else @click="stopManaging">
              Stop Managing
            </button>
          </div>
        </div>
      </div>

      <hr class="mt-2 mb-4" />
      <AlbumDescriptionEditable
        v-if="canEditAlbum"
        :album="album"
        @update-description="updateAlbumDescription"
      />
      <div
        v-else
        class="content"
        v-html="descriptionHtml"
        v-if="album.descriptionHtml"
      />

      <AlbumManagement
        v-if="
          !loading &&
          userStore.signedIn &&
          album.canEdit &&
          applicationStore.managingAlbum
        "
        :album="album"
        @delete-album="deleteAlbum"
        @update-sorting="updateAlbumSorting"
        @set-album-privacy="handleSetAlbumPrivacy"
      />

      <SelectionOptions
        v-if="
          !loading &&
          userStore.signedIn &&
          album.canEdit &&
          applicationStore.managingAlbum
        "
        :photos="album.photos.collection"
        :album-id="id"
        @request-remove-from-album="openRemoveFromAlbumModal"
      />

      <div class="columns is-1 is-multiline" :class="{ 'mt-0': canEditAlbum }">
        <PhotoItem
          v-for="photo in album.photos.collection"
          :photo="photo"
          :in-album="true"
          :key="photo.id"
          :can-edit-album="canEditAlbum"
          @set-cover-photo="handleSetAlbumCoverPhoto"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="album.photos.metadata"
        :metadata="album.photos.metadata"
        :routeParams="{ id: id }"
        routeName="albums-show"
      />
    </div>
  </section>

  <!-- Stop Managing confirmation modal -->
  <teleport to="#modal-root">
    <div :class="['modal', stopManagingModalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Stop Managing Album</p>
        </header>
        <div class="modal-card-body">
          <p>
            You have selected photos in this album. Stopping album management
            will clear the selection. Continue?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="confirmStopManaging">
              Yes, clear selection
            </button>
            <button class="button is-info" @click="cancelStopManaging">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
  <!-- Remove From Album confirmation modal -->
  <teleport to="#modal-root">
    <div :class="['modal', removeFromAlbumModalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Remove From Album</p>
        </header>
        <div class="modal-card-body">
          <p>
            You are about to remove
            <strong>{{ selectionStore.selectedAlbumPhotos.length }}</strong>
            {{
              selectionStore.selectedAlbumPhotos.length === 1
                ? "photo"
                : "photos"
            }}
            from this album. Continue?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="confirmRemoveFromAlbum">
              Yes, remove
            </button>
            <button class="button is-info" @click="cancelRemoveFromAlbum">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed, inject, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useApplicationStore } from "@/stores/application";
import { useUserStore } from "../stores/user";
import { useSelectionStore } from "../stores/selection";
import toaster from "../mixins/toaster";
import titleHelper from "../mixins/title-helper";
import { descriptionHtmlHelper } from "../mixins/description-helper";

// components
import AlbumTitleEditable from "./album-title-editable.vue";
import AlbumDescriptionEditable from "./album-description-editable.vue";
import AlbumManagement from "./album-management.vue";
import SelectionOptions from "./selection-options.vue";
import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";

// route
const route = useRoute();
const router = useRouter();

const emptyAlbum = {
  title: "",
  photos: [],
};

const applicationStore = useApplicationStore();
const userStore = useUserStore();
const selectionStore = useSelectionStore();

const id = computed(() => route.params.id);
const page = computed(() => parseInt(route.query.page) || 1);

const stopManagingModalActive = ref(false);
const removeFromAlbumModalActive = ref(false);

const stopManaging = () => {
  const hasSelection = (selectionStore.selectedAlbumPhotos || []).length > 0;

  if (hasSelection) {
    stopManagingModalActive.value = true;
    applicationStore.disableNavigationShortcuts();
  } else {
    applicationStore.stopManagingAlbum();
  }
};

const confirmStopManaging = () => {
  selectionStore.clearSelectedAlbumPhotos();
  applicationStore.stopManagingAlbum();
  stopManagingModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const cancelStopManaging = () => {
  stopManagingModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const apolloClient = inject("apolloClient");

const { result, loading } = useQuery(
  gql`
    ${gql_queries.albums_show}
  `,
  { id: id, page: page },
);

const album = computed(() => result.value?.album ?? emptyAlbum);

const title = computed(() => `Album: ${titleHelper(album, loading)}`);
useTitle(title);

const canEditAlbum = computed(
  () => !loading.value && userStore.signedIn && album.value.canEdit,
);

const descriptionHtml = computed(() => descriptionHtmlHelper(album, loading));

const {
  mutate: updateAlbumTitle,
  onDone: onUpdateTitleDone,
  onError: onUpdateTitleError,
} = useMutation(gql`
  mutation ($id: String!, $title: String!) {
    updateAlbumTitle(id: $id, title: $title) {
      id
      title
    }
  }
`);

const {
  mutate: updateAlbumDescription,
  onDone: onUpdateDescriptionDone,
  onError: onUpdateDescriptionError,
} = useMutation(gql`
  mutation ($id: String!, $description: String!) {
    updateAlbumDescription(id: $id, description: $description) {
      id
      description
    }
  }
`);

const {
  mutate: deleteAlbum,
  onDone: onDeleteAlbumDone,
  onError: onDeleteAlbumError,
} = useMutation(gql`
  mutation ($id: String!) {
    deleteAlbum(id: $id) {
      errors
      album {
        id
      }
    }
  }
`);

const {
  mutate: updateAlbumPhotoOrder,
  onDone: onUpdateAlbumPhotoOrderDone,
  onError: onUpdateAlbumPhotoOrderError,
} = useMutation(gql`
  mutation UpdateAlbumPhotoOrder(
    $albumId: ID!
    $sortingType: String!
    $sortingOrder: String!
    $orders: [AlbumPhotoOrderInput!]
    $page: Int
  ) {
    updateAlbumPhotoOrder(
      albumId: $albumId
      sortingType: $sortingType
      sortingOrder: $sortingOrder
      orders: $orders
    ) {
      errors
      album {
        id
        sortingType
        sortingOrder
        photos(page: $page) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(
              type: "intelligent_or_square_medium"
            )
            canEdit
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
      }
    }
  }
`);

onUpdateTitleDone(({ data }) => {
  toaster("The title has been updated");
});

onUpdateTitleError((error) => {
  toaster(
    "An error occurred while updating the title: " + error.message,
    "is-danger",
  );
});

onUpdateDescriptionDone(({ data }) => {
  toaster("The description has been updated");
});

onUpdateDescriptionError((error) => {
  toaster(
    "An error occurred while updating the description: " + error.message,
    "is-danger",
  );
});

onDeleteAlbumDone(({ data }) => {
  const payload = data?.deleteAlbum;

  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg =
      (payload && payload.errors && payload.errors.join(", ")) ||
      "Unknown error";
    toaster("An error occurred while deleting the album: " + msg, "is-danger");
    return;
  }

  toaster("The album has been deleted");
  applicationStore.stopManagingAlbum();
  apolloClient.cache.evict({
    id: apolloClient.cache.identify({ __typename: "Album", id: id.value }),
  });
  apolloClient.cache.evict({ fieldName: "albums" });
  apolloClient.cache.gc();
  router.push({ name: "albums-index" });
});

onDeleteAlbumError((error) => {
  toaster(
    "An error occurred while deleting the album: " + error.message,
    "is-danger",
  );
});

/* Set album privacy mutation */
const {
  mutate: setAlbumPrivacyMutation,
  onDone: onSetAlbumPrivacyDone,
  onError: onSetAlbumPrivacyError,
} = useMutation(gql`
  mutation ($id: String!, $privacy: String!, $updatePhotos: Boolean!) {
    setAlbumPrivacy(id: $id, privacy: $privacy, updatePhotos: $updatePhotos) {
      album {
        id
        privacy
      }
      photosUpdatedCount
    }
  }
`);

const handleSetAlbumPrivacy = ({ id, privacy, updatePhotos }) => {
  setAlbumPrivacyMutation({ id, privacy, updatePhotos });
};

onSetAlbumPrivacyDone(({ data }) => {
  const photosUpdatedCount = data?.setAlbumPrivacy?.photosUpdatedCount || 0;
  if (photosUpdatedCount > 0) {
    toaster(
      `Album privacy has been updated. ${photosUpdatedCount} ${photosUpdatedCount === 1 ? "photo" : "photos"} also set to private.`
    );
  } else {
    toaster("Album privacy has been updated");
  }
  // Evict albums list to refresh visibility if necessary
  apolloClient.cache.evict({ fieldName: "albums" });
  apolloClient.cache.gc();
});

onSetAlbumPrivacyError((error) => {
  toaster(
    "An error occurred while updating album privacy: " + error.message,
    "is-danger",
  );
});

const updateAlbumSorting = (sortingData) => {
  const variables = {
    albumId: sortingData.id,
    sortingType: sortingData.sortingType,
    sortingOrder: sortingData.sortingOrder,
    page: page.value,
  };

  updateAlbumPhotoOrder(variables);
};

onUpdateAlbumPhotoOrderDone((result) => {
  if (result.data.updateAlbumPhotoOrder.errors.length > 0) {
    toaster(
      "Error updating album sorting: " +
        result.data.updateAlbumPhotoOrder.errors.join(", "),
      "is-danger",
    );
  } else {
    toaster("Album sorting has been updated");
    apolloClient.cache.evict({
      id: apolloClient.cache.identify({ __typename: "Album", id: id.value }),
      fieldName: "photos",
    });
    apolloClient.cache.gc();
  }
});

onUpdateAlbumPhotoOrderError((error) => {
  toaster(
    "An error occurred while updating album sorting: " + error.message,
    "is-danger",
  );
});
/* Remove photos from album mutation */
const {
  mutate: removePhotosFromAlbum,
  onDone: onRemovePhotosFromAlbumDone,
  onError: onRemovePhotosFromAlbumError,
} = useMutation(gql`
  mutation RemovePhotosFromAlbum(
    $albumId: String!
    $photoIds: [String!]!
    $page: Int
  ) {
    removePhotosFromAlbum(albumId: $albumId, photoIds: $photoIds) {
      errors
      album {
        id
        title
        photos(page: $page) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(
              type: "intelligent_or_square_medium"
            )
            canEdit
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
      }
    }
  }
`);

const openRemoveFromAlbumModal = () => {
  const hasSelection = (selectionStore.selectedAlbumPhotos || []).length > 0;
  if (hasSelection) {
    removeFromAlbumModalActive.value = true;
    applicationStore.disableNavigationShortcuts();
  }
};

const confirmRemoveFromAlbum = () => {
  const photoIds = (selectionStore.selectedAlbumPhotos || []).map((p) => p.id);
  if (photoIds.length === 0) return;

  removePhotosFromAlbum({
    albumId: id.value,
    photoIds,
    page: page.value,
  });
};

const cancelRemoveFromAlbum = () => {
  removeFromAlbumModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

onRemovePhotosFromAlbumDone(({ data }) => {
  const payload = data?.removePhotosFromAlbum;

  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg =
      (payload && payload.errors && payload.errors.join(", ")) ||
      "Unknown error";
    toaster("Error removing photos from album: " + msg, "is-danger");
    removeFromAlbumModalActive.value = false;
    applicationStore.enableNavigationShortcuts();
    return;
  }

  selectionStore.clearSelectedAlbumPhotos();

  toaster(
    "The photos were removed from the album '" +
      (payload.album?.title || "") +
      "'",
    "is-success",
  );

  const albumCacheId = apolloClient.cache.identify({
    __typename: "Album",
    id: id.value,
  });

  // Evict album photos so the list reloads with updated content
  apolloClient.cache.evict({ id: albumCacheId, fieldName: "photos" });
  apolloClient.cache.gc();

  removeFromAlbumModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
});

onRemovePhotosFromAlbumError((error) => {
  toaster(
    "An error occurred while removing photos from the album: " + error.message,
    "is-danger",
  );
  removeFromAlbumModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
});

/* Cover photo mutation */
const {
  mutate: setAlbumCoverPhotoMutation,
  onDone: onSetAlbumCoverPhotoDone,
  onError: onSetAlbumCoverPhotoError,
} = useMutation(gql`
  mutation SetAlbumCoverPhoto(
    $albumId: String!
    $photoId: String!
    $page: Int
  ) {
    setAlbumCoverPhoto(albumId: $albumId, photoId: $photoId) {
      errors
      album {
        id
        photos(page: $page) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(
              type: "intelligent_or_square_medium"
            )
            canEdit
            isCoverPhoto
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
      }
    }
  }
`);

const handleSetAlbumCoverPhoto = (photo) => {
  const variables = {
    albumId: id.value,
    photoId: photo.id,
    page: page.value,
  };
  setAlbumCoverPhotoMutation(variables);
};

onSetAlbumCoverPhotoDone((result) => {
  const payload = result?.data?.setAlbumCoverPhoto;
  if (!payload || (payload.errors && payload.errors.length > 0)) {
    const msg =
      (payload && payload.errors && payload.errors.join(", ")) ||
      "Unknown error";
    toaster("Error setting cover photo: " + msg, "is-danger");
  } else {
    toaster("Cover photo updated");
    const albumCacheId = apolloClient.cache.identify({
      __typename: "Album",
      id: id.value,
    });
    // Evict album's coverPhoto so album indices refetch the cover image
    apolloClient.cache.evict({
      id: albumCacheId,
      fieldName: "coverPhoto",
    });

    apolloClient.cache.gc();
  }
});

onSetAlbumCoverPhotoError((error) => {
  toaster(
    "An error occurred while setting the cover photo: " + error.message,
    "is-danger",
  );
});
</script>

<style></style>
