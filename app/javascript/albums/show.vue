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
        <div class="level-right" v-if="userStore.signedIn">
          <div class="level-item" v-if="userStore.uploader">
            <p class="selection-hint touch-only">
              <span class="icon"><i class="far fa-hand-pointer"></i></span>
              <span>{{ selectionHint }}</span>
            </p>
          </div>
          <div class="level-item" v-if="canEditAlbum">
            <button class="button is-small" @click="showAlbumSettings = !showAlbumSettings">
              {{ showAlbumSettings ? "Hide Album Settings" : "Album Settings" }}
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
        v-if="!loading && userStore.signedIn && album.canEdit && showAlbumSettings"
        ref="albumManagementRef"
        :album="album"
        @delete-album="deleteAlbum"
        @update-sorting="updateAlbumSorting"
        @set-album-privacy="handleSetAlbumPrivacy"
      />

      <div class="columns is-1 is-multiline" :class="{ 'mt-0': canEditAlbum }">
        <PhotoItem
          v-for="photo in album.photos?.collection"
          :photo="photo"
          :in-album="true"
          :album-id="id"
          :key="photo.id"
          :can-edit-album="canEditAlbum"
          @set-cover-photo="handleSetAlbumCoverPhoto"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="album.photos?.metadata"
        :metadata="album.photos.metadata"
        :routeParams="{ id: id }"
        routeName="albums-show"
      />
    </div>
  </section>
</template>

<script setup>
import { computed, inject, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "../stores/user";
import { useSelectionStore } from "../stores/selection";
import { useSelectionContext } from "../mixins/use-selection-context";
import toaster from "../mixins/toaster";
import titleHelper from "../mixins/title-helper";
import { descriptionHtmlHelper } from "../mixins/description-helper";

// components
import AlbumTitleEditable from "./album-title-editable.vue";
import AlbumDescriptionEditable from "./album-description-editable.vue";
import AlbumManagement from "./album-management.vue";
import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";

// route
const route = useRoute();
const router = useRouter();
const albumManagementRef = ref(null);

const userStore = useUserStore();
const selectionStore = useSelectionStore();
useSelectionContext();

const id = computed(() => route.params.id);
const page = computed(() => parseInt(route.query.page) || 1);

const showAlbumSettings = ref(false);

const apolloClient = inject("apolloClient");

const { result, loading } = useQuery(
  gql`
    ${gql_queries.albums_show}
  `,
  { id: id, page: page },
  { keepPreviousResult: true },
);

const album = computed(() => result.value?.album ?? {});

const title = computed(() => `Album: ${titleHelper(album)}`);
useTitle(title);

// The id check matters because keepPreviousResult retains the outgoing album
// while the next one loads: without it the title and description editors
// would stay live over an album the URL has already moved away from. Paging
// within one album keeps the same id, so editing stays available there.
const canEditAlbum = computed(
  () => userStore.signedIn && album.value.canEdit && album.value.id === id.value,
);

// Long press reveals both the checkbox and the cover-photo star, but only
// someone who can edit the album gets the latter.
const selectionHint = computed(() =>
  canEditAlbum.value
    ? "Long press a photo to select it or to set the cover photo"
    : "Long press a photo to start selecting",
);

const descriptionHtml = computed(() => descriptionHtmlHelper(album));

watch(
  () => album.value.photos?.collection,
  (photos) => selectionStore.setPageCollection(photos || []),
  { immediate: true },
);

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
        privatizablePhotosCount
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
  if (photosUpdatedCount > 0) {
    // Cascaded photos may be cached elsewhere (e.g. a photo page) still showing the old privacy
    apolloClient.cache.evict({ fieldName: "photo" });
  }
  apolloClient.cache.gc();
});

onSetAlbumPrivacyError((error) => {
  toaster(
    "An error occurred while updating album privacy: " + error.message,
    "is-danger",
  );
  albumManagementRef.value?.revertPrivacy();
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

/* Cover photo mutation (per-card star, independent of the selection bar's
   own "Set As Cover" action) */
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
