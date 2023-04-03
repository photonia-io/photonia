<template>
  <div class="column is-one-quarter">
    <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
      <img
        v-if="photo.intelligentOrSquareMediumImageUrl"
        :src="photo.intelligentOrSquareMediumImageUrl"
        class="image is-fullwidth"
      />
      <ImagePlaceholder
        v-else
      />
      {{ photo.name }}
    </router-link>
  </div>
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
