<template>
  <SectionRow
    v-if="loading || album"
    :title="album ? `Album Spotlight: ${album.title}` : 'Album spotlight'"
    :to="album ? { name: 'albums-show', params: { id: album.id } } : null"
    :link-label="`View album (${album?.photosCount ?? 0} photos)...`"
    :loading="loading"
  >
    <template v-if="album?.descriptionHtml" #intro>
      <div class="content spotlight-description" v-html="album.descriptionHtml"></div>
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
