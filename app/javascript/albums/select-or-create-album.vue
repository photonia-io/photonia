<template>
  <div class="field" v-if="newAlbumTitle === ''">
    <label class="label">Pick an album</label>
    <div class="control">
      <div class="select">
        <select v-model="selectedAlbumId">
          <option selected></option>
          <option
            v-if="result && result.allAlbums"
            v-for="album in result.allAlbums"
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
    existing album, please delete the name from the below and select an album
    from the dropdown that appears here.
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
    <strong v-if="result && result.allAlbums">
      {{ result.allAlbums.find((album) => album.id === selectedAlbumId).title }}
    </strong>
    above. If you wish to create a new album, please select the first (empty)
    option above then enter a title in the field that appears here.
  </p>
</template>

<script setup>
import { ref } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

const selectedAlbumId = ref("");
const newAlbumTitle = ref("");

const reset = () => {
  selectedAlbumId.value = "";
  newAlbumTitle.value = "";
};

defineExpose({ selectedAlbumId, newAlbumTitle, reset });

const { result } = useQuery(gql`
  query AllAlbumsQuery {
    allAlbums {
      id
      title
      photosCount
    }
  }
`);
</script>
