<template>
  <h2 class="title is-3 mb-2">Random Photos</h2>
  <hr class="mt-0 mb-3" />
  <div class="columns is-multiline">
    <div v-for="photo in photos" class="column is-half">
      <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
        <img
          v-if="photo.intelligentOrSquareMediumImageUrl"
          :src="photo.intelligentOrSquareMediumImageUrl"
          class="image is-fullwidth"
        />
        <ImagePlaceholder v-else />
        {{ photo.title }}
      </router-link>
    </div>
  </div>
</template>

<script setup>
import ImagePlaceholder from "@/shared/image-placeholder.vue";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});
</script>
