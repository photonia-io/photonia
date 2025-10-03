<template>
  <div class="column is-one-quarter is-relative grabbable">
    <ItemImage :photo="photo" />
    {{ photo.title }}
  </div>
</template>

<script setup>
import ItemImage from "@/shared/item-image.vue";
const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});
</script>

<style scoped>
.grabbable {
  cursor: move;
}
</style>
