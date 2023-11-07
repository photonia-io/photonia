<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Organizer</h1>
          </div>
        </div>
        <div class="level-right">
          <div class="level-item">
            <ReturnToPreviousPage />
          </div>
        </div>
      </div>
      <hr class="mt-2 mb-4" />
      <SelectionActions :photos="selectionStore.selectedPhotos" />
      <div class="columns is-1 is-variable is-multiline">
        <PhotoItem
          v-for="photo in selectionStore.selectedPhotos"
          :photo="photo"
          :key="photo.id"
        />
      </div>
    </div>
  </section>
</template>

<script setup>
import { watch } from "vue";
import { storeToRefs } from "pinia";
import { useTitle } from "vue-page-title";

import { useSelectionStore } from "@/stores/selection";

import ReturnToPreviousPage from "@/shared/return-to-previous-page.vue";
import PhotoItem from "@/shared/photo-item.vue";
import SelectionActions from "@/photos/selection-actions.vue";
import toaster from "@/mixins/toaster";

const selectionStore = useSelectionStore();
const { selectedPhotos } = storeToRefs(selectionStore);

useTitle("Organizer");

watch(selectedPhotos, (newValue, oldValue) => {
  if (selectionStore.showRemoveNotification == false) {
    selectionStore.showRemoveNotification = true;
    return;
  }

  if (newValue.length < oldValue.length) {
    const removedPhoto = oldValue
      .filter((photo) => !newValue.includes(photo))
      .pop();
    toaster(`"${removedPhoto.title}" was removed from the selection`);
  }
});
</script>
