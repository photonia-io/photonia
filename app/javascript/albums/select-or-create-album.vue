<template>
  <div class="field" v-if="newAlbumTitle === ''">
    <label class="label">Pick an album</label>
    <div class="control">
      <div class="select is-fullwidth">
        <select v-model="selectedAlbumId">
          <option selected></option>
          <option
            v-if="result && result.currentUser.albums"
            v-for="album in albumsFiltered"
            :key="album.id"
            :value="album.id"
          >
            {{ album.title }} ({{
              album.photosCount > 0 ? album.photosCount : "no"
            }}
            photo{{ album.photosCount != 1 ? "s" : "" }})
          </option>
        </select>
      </div>
    </div>
  </div>
  <p v-else>
    You have entered a name for a new album below. If you wish to select an
    existing album, please delete the name from the text box below and select an
    album from the dropdown that appears here.
  </p>
  <div class="divider">Or create new</div>
  <div class="field" v-if="selectedAlbumId === ''">
    <label class="label">Title</label>
    <div class="control">
      <input class="input" type="text" v-model="newAlbumTitle" />
    </div>
  </div>
  <p v-else>
    You have selected
    <strong v-if="result && result.currentUser.albums">
      {{ albumsFiltered.find((album) => album.id === selectedAlbumId)?.title }}
    </strong>
    above. If you wish to create a new album, please select the first (empty)
    option above then enter a title in the field that appears here.
  </p>
</template>

<script setup>
import { ref, computed } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

const props = defineProps({
  photos: {
    type: Array,
    required: false,
    default: () => [],
  },
  hideAlbumId: {
    type: String,
    required: false,
    default: "",
  },
});

const photoIds = computed(() => props.photos.map((photo) => photo.id));

const selectedAlbumId = ref("");
const newAlbumTitle = ref("");

const reset = () => {
  selectedAlbumId.value = "";
  newAlbumTitle.value = "";
};

defineExpose({ selectedAlbumId, newAlbumTitle, reset });

const { result } = useQuery(
  gql`
    query CurrentUserAlbumsQuery($photoIds: [String!]!) {
      currentUser {
        albums {
          id
          title
          photosCount
        }
        albumsWithPhotos(photoIds: $photoIds) {
          id
          containedPhotosCount
        }
      }
    }
  `,
  { photoIds: photoIds },
);

// Offer an album only while at least one of the photos is still missing from
// it, plus the explicit hideAlbumId opt-out.
const albumsFiltered = computed(() => {
  const albums = result.value?.currentUser?.albums || [];
  const alreadyHasAll = new Set(
    (result.value?.currentUser?.albumsWithPhotos || [])
      .filter((album) => album.containedPhotosCount >= photoIds.value.length)
      .map((album) => album.id),
  );

  return albums.filter(
    (album) => !alreadyHasAll.has(album.id) && album.id !== props.hideAlbumId,
  );
});
</script>
