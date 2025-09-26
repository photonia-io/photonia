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
          <div class="buttons">TODO</div>
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
import { computed } from "vue";

import { useSelectionStore } from "@/stores/selection";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

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
</script>
