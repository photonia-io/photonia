<template>
  <div class="column is-one-quarter is-relative">
    <router-link
      v-if="!applicationStore.selectionMode"
      :to="{ name: 'photos-show', params: { id: photo.id } }"
    >
      <ItemImage :photo="photo" />
      {{ photo.name }}
    </router-link>
    <div v-else>
      <div class="selectable-item is-clickable" @click="toggleSelection()">
        <ItemImage :photo="photo" />
        <ItemCheckbox
          v-if="userStore.signedIn && applicationStore.selectionMode"
          :checked="selected"
        />
      </div>
      <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
        {{ photo.name }}
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";

import { useUserStore } from "@/stores/user";
import { useApplicationStore } from "@/stores/application";
import { useSelectionStore } from "@/stores/selection";

import ItemImage from "@/shared/item-image.vue";
import ItemCheckbox from "@/shared/item-checkbox.vue";

const userStore = useUserStore();
const applicationStore = useApplicationStore();
const selectionStore = useSelectionStore();

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const selected = computed(() => {
  return selectionStore.selectedPhotos.some(
    (photo) => photo.id === props.photo.id
  );
});

const toggleSelection = () => {
  if (selected.value) {
    selectionStore.removePhoto(props.photo);
  } else {
    selectionStore.addPhoto(props.photo);
  }
};
</script>

<style>
.selectable-item:hover .item-checkbox {
  border-color: #00d1b2;
}
</style>
