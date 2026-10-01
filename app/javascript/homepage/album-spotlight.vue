<template>
  <SectionRow
    v-if="loading || album"
    title="Album Spotlight"
    :to="album ? { name: 'albums-show', params: { id: album.id } } : null"
    link-label="View album..."
    :loading="loading"
  >
    <template #intro>
      <!-- nbsp keeps the line's height while the album is still loading -->
      <h3 class="title is-5 mb-2">{{ album?.title ?? "\u00a0" }}</h3>
      <div
        v-if="album?.descriptionHtml"
        class="content spotlight-description"
        v-html="album.descriptionHtml"
      ></div>
    </template>
    <HomeTile
      v-for="photo in photos"
      :key="photo.id"
      :to="{ name: 'photos-show', params: { id: photo.id }, query: { inAlbum: album.id } }"
      :title="photo.title"
      :image-url="photo.intelligentOrSquareMediumImageUrl"
    />
  </SectionRow>
</template>

<script setup>
import { computed } from "vue";

import SectionRow from "./section-row.vue";
import HomeTile from "./home-tile.vue";

const props = defineProps({
  album: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const TILES = 5;
const photos = computed(() => (props.album?.photos?.collection ?? []).slice(0, TILES));
</script>

<style scoped>
/* Keep the intro to a few lines; the album page has the full text */
.spotlight-description {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
