<template>
  <div class="column is-one-quarter">
    <router-link :to="{ name: 'albums-show', params: { id: album.id } }">
      <img
        v-if="
          album.publicCoverPhoto &&
          album.publicCoverPhoto.intelligentOrSquareMediumImageUrl
        "
        :src="album.publicCoverPhoto.intelligentOrSquareMediumImageUrl"
        class="image is-fullwidth album-item"
      />
      <ImagePlaceholder v-else />
      {{ album.title }}
    </router-link>
    ({{ album.publicPhotosCount }}
    {{ album.publicPhotosCount == 1 ? "photo" : "photos" }})
  </div>
</template>

<script setup>
import ImagePlaceholder from "@/shared/image-placeholder.vue";

const props = defineProps({
  album: {
    type: Object,
    required: true,
  },
});
</script>

<style>
.album-item {
  border-radius: 0.3rem;
}
</style>
