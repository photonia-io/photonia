<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Sort photos in: {{ album.title }}</h1>
          </div>
        </div>
        <div class="level-right">
          <div class="level-item">
            <router-link
              class="button is-small"
              :to="{ name: 'albums-show', params: { id } }"
            >
              Back to album
            </router-link>
          </div>
        </div>
      </div>
      <hr class="mt-2 mb-4" />
      <div class="message is-warning is-smallish">
        <div class="message-body">
          <p class="mb-3">
            You can use the Pre-Sort dropdowns to set an initial sort order and
            then you can drag and drop photos to reorder them.
          </p>
          <p class="mb-3">Changes are saved instantly.</p>

          <label for="album-sorting-type" class="label">Pre-Sort:</label>

          <div class="select is-small">
            <select
              id="album-sorting-type"
              v-model="sortingType"
              @change="preSort"
            >
              <option value="takenAt">Date Shot</option>
              <option value="postedAt">Date Uploaded</option>
              <option value="title">Title</option>
              <option v-if="sortingType === 'manual'" value="manual">
                Manual (custom order)
              </option>
            </select>
          </div>
          <div
            class="select is-small ml-2"
            @change="preSort"
            v-if="sortingType != 'manual'"
          >
            <select id="album-sorting-order" v-model="sortingOrder">
              <option value="asc">{{ sortingOrderAscendingText }}</option>
              <option value="desc">{{ sortingOrderDescendingText }}</option>
            </select>
          </div>
          <p class="mt-3">
            Automatic sorting:
            <span v-if="sortingType != 'manual'"><strong>enabled</strong></span>
            <span v-else>disabled</span>
          </p>
        </div>
      </div>
      <VueDraggable
        :animation="200"
        @update="manualSort"
        v-model="photos"
        class="columns is-1 is-multiline mt-0"
        v-if="!loading"
      >
        <PhotoItemSortable
          v-for="photo in photos"
          :photo="photo"
          :key="photo.id"
        />
      </VueDraggable>
    </div>
  </section>
</template>

<script setup>
import { computed, ref, watch, inject } from "vue";
import { useRoute } from "vue-router";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { VueDraggable } from "vue-draggable-plus";

// components
import PhotoItemSortable from "./photo-item-sortable.vue";

// route
const route = useRoute();

const id = computed(() => route.params.id);

const apolloClient = inject("apolloClient");

const emptyAlbum = {
  title: "",
  allPhotos: [],
};

const sortingType = ref("takenAt");
const sortingOrder = ref("asc");

const sortingOrderAscendingText = computed(() => {
  return sortingType.value != "title" ? "Oldest First" : "A - Z";
});

const sortingOrderDescendingText = computed(() => {
  return sortingType.value != "title" ? "Newest First" : "Z - A";
});

const photos = ref([]);

const ALBUM_FIELDS = `
  id
  title
  sortingType
  sortingOrder
  allPhotos {
    id
    title
    intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
    takenAt
    postedAt
    ordering
  }
`;

const ALL_PHOTOS_QUERY = gql`
  query AllPhotos($id: ID!) {
    album(id: $id) {
      ${ALBUM_FIELDS}
    }
  }
`;

const UPDATE_ALBUM_PHOTO_ORDER_MUTATION = gql`
  mutation UpdateAlbumPhotoOrder(
    $albumId: ID!
    $sortingType: String!
    $sortingOrder: String!
    $orders: [AlbumPhotoOrderInput!]
  ) {
    updateAlbumPhotoOrder(
      albumId: $albumId
      sortingType: $sortingType
      sortingOrder: $sortingOrder
      orders: $orders
    ) {
      errors
      album {
        ${ALBUM_FIELDS}
      }
    }
  }
`;

const { result, loading } = useQuery(
  gql`
    ${ALL_PHOTOS_QUERY}
  `,
  { id: id },
);

const album = computed(() => result.value?.album ?? emptyAlbum);

watch(album, (newAlbum) => {
  console.log("Album changed, updating photos");
  // log the first photo's title to the console
  if (newAlbum.allPhotos.length > 0) {
    console.log("First photo title:", newAlbum.allPhotos[0].title);
  } else {
    console.log("No photos in the album");
  }
  photos.value = newAlbum.allPhotos;
  sortingType.value = newAlbum.sortingType;
  sortingOrder.value = newAlbum.sortingOrder;
});

const {
  mutate: updateAlbumPhotoOrder,
  onDone: onUpdateAlbumPhotoOrderDone,
  onError: onUpdateAlbumPhotoOrderError,
} = useMutation(gql`
  ${UPDATE_ALBUM_PHOTO_ORDER_MUTATION}
`);

onUpdateAlbumPhotoOrderDone((result) => {
  const errors = result?.data?.updateAlbumPhotoOrder?.errors || [];
  if (errors.length > 0) {
    console.error("Error updating album photo order:", errors);
    return;
  }
  // Clear Apollo cache for current album's photos to force refetch
  apolloClient.cache.evict({
    id: apolloClient.cache.identify({ __typename: "Album", id: id.value }),
    fieldName: "photos",
  });
  apolloClient.cache.gc();
});

onUpdateAlbumPhotoOrderError((error) => {
  console.error("GraphQL error updating album photo order:", error);
});

const manualSort = () => {
  sortingType.value = "manual";
  setOrderingAndSave(photos.value, true);
};

const preSort = () => {
  let sortedPhotos = [];
  if (sortingType.value === "takenAt") {
    sortedPhotos = photos.value.slice().sort((a, b) => {
      const dateA = new Date(a.takenAt);
      const dateB = new Date(b.takenAt);
      return sortingOrder.value === "asc" ? dateA - dateB : dateB - dateA;
    });
  } else if (sortingType.value === "postedAt") {
    sortedPhotos = photos.value.slice().sort((a, b) => {
      const dateA = new Date(a.postedAt);
      const dateB = new Date(b.postedAt);
      return sortingOrder.value === "asc" ? dateA - dateB : dateB - dateA;
    });
  } else if (sortingType.value === "title") {
    sortedPhotos = photos.value.slice().sort((a, b) => {
      const titleA = a.title.toLowerCase();
      const titleB = b.title.toLowerCase();
      if (titleA < titleB) return sortingOrder.value === "asc" ? -1 : 1;
      if (titleA > titleB) return sortingOrder.value === "asc" ? 1 : -1;
      return 0;
    });
  }

  setOrderingAndSave(sortedPhotos);
};

const setOrderingAndSave = (newPhotos, manual = false) => {
  // Set the ordering field, increasing by 100000
  photos.value = newPhotos.map((photo, idx) => ({
    ...photo,
    ordering: (idx + 1) * 100000,
  }));

  const variables = {
    albumId: id.value,
    sortingType: sortingType.value,
    sortingOrder: sortingOrder.value,
  };

  if (manual === true) {
    variables.orders = photos.value.map((photo) => ({
      photoId: photo.id,
      ordering: photo.ordering,
    }));
  }

  // call the mutation
  updateAlbumPhotoOrder(variables);
};
</script>
