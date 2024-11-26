<template>
  <div
    class="field"
    v-if="result && result.currentUser.albumsWithPhotos.length"
  >
    <label class="label">Pick an album</label>
    <div class="control">
      <div class="select">
        <select v-model="selectedAlbumId">
          <option selected></option>
          <option
            v-if="result && result.currentUser.albumsWithPhotos"
            v-for="album in result.currentUser.albumsWithPhotos"
            :key="album.id"
            :value="album.id"
          >
            {{ album.title }} (Remove {{ album.containedPhotosCount }} photo{{
              album.containedPhotosCount != 1 ? "s" : ""
            }})
          </option>
        </select>
      </div>
    </div>
  </div>
  <p v-else>You have no albums that contain the selected photos.</p>
</template>

<script setup>
import { computed, ref } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

const photoIds = computed(() => props.photos.map((photo) => photo.id));

const selectedAlbumId = ref("");

const reset = () => {
  selectedAlbumId.value = "";
};

defineExpose({ selectedAlbumId, reset });

// graphql query to get albums that contain the selected photos

const { result } = useQuery(
  gql`
    query CurrentUserAlbumsWithPhotosQuery($photoIds: [String!]!) {
      currentUser {
        albumsWithPhotos(photoIds: $photoIds) {
          id
          title
          containedPhotosCount
        }
      }
    }
  `,
  {
    photoIds: photoIds,
  },
);
</script>
