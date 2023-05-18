<template>
  <img
    v-if="photo.intelligentOrSquareMediumImageUrl"
    :src="photo.intelligentOrSquareMediumImageUrl"
    class="image is-fullwidth image-item"
  />
  <ImagePlaceholder
    v-else
  />
</template>

<script setup>
  import ImagePlaceholder from '@/shared/image-placeholder.vue'

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    }
  })
</script>

<style>
  .image-item {
    border-radius: 0.3rem;
  }
</style>
