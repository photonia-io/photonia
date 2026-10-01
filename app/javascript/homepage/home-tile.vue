<template>
  <router-link :to="to" class="home-tile">
    <div class="home-tile-image">
      <img
        v-if="imageUrl"
        :src="imageUrl"
        :alt="title"
        class="image is-fullwidth"
      />
      <ImagePlaceholder v-else />
      <span v-if="count" class="tag is-dark is-small icon-text home-tile-count">
        <span class="icon"><i class="fas fa-images"></i></span>
        <span>{{ count }}</span>
      </span>
    </div>
    {{ title }}
    <span v-if="subtitle" class="home-tile-subtitle is-size-7">{{ subtitle }}</span>
  </router-link>
</template>

<script setup>
import ImagePlaceholder from "@/shared/image-placeholder.vue";

defineProps({
  to: { type: Object, required: true },
  title: { type: String, default: "" },
  // small line under the title, e.g. "12 years ago"
  subtitle: { type: String, default: null },
  imageUrl: { type: String, default: null },
  // photo count badge, for albums and collapsed albums
  count: { type: Number, default: null },
});
</script>

<style scoped lang="scss">
.home-tile-image {
  position: relative;

  // Reserve the square before the image arrives, so loading never shifts the page.
  aspect-ratio: 1;
  border-radius: 0.3rem;
  background-color: var(--bulma-background, #eee);

  img {
    height: 100%;
    object-fit: cover;
    border-radius: 0.3rem;
  }
}

.home-tile-subtitle {
  display: block;
  color: var(--bulma-text-weak, #6b6b6b);
}

.home-tile-count {
  position: absolute;
  right: 0.75em;
  bottom: 0.75em;
}
</style>
