<template>
  <!-- keeps its line while loading so the page doesn't shift when it fills in -->
  <p class="home-stats has-text-centered is-size-6 mb-4">
    <template v-if="parts.length">
      <template v-for="(part, index) in parts" :key="index">
        <span v-if="index > 0" class="home-stats-separator">&#9670;</span>
        <router-link v-if="part.to" :to="part.to">{{ part.text }}</router-link>
        <span v-else>{{ part.text }}</span>
      </template>
    </template>
    <template v-else>&nbsp;</template>
  </p>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  stats: { type: Object, default: null },
});

const number = new Intl.NumberFormat("en");
const compact = new Intl.NumberFormat("en", {
  notation: "compact",
  maximumFractionDigits: 1,
});

const parts = computed(() => {
  const stats = props.stats;
  if (!stats) return [];

  const result = [
    { text: `${number.format(stats.photosCount)} photos`, to: { name: "photos-index" } },
    { text: `${number.format(stats.albumsCount)} albums`, to: { name: "albums-index" } },
  ];
  if (stats.firstYear && stats.lastYear) {
    result.push({
      text:
        stats.firstYear === stats.lastYear
          ? `${stats.firstYear}`
          : `${stats.firstYear} - ${stats.lastYear}`,
    });
  }
  if (stats.viewsCount > 0) {
    result.push({ text: `${compact.format(stats.viewsCount)} views` });
  }

  return result;
});
</script>

<style scoped>
.home-stats {
  min-height: 1.5em;
  color: var(--bulma-text-weak, #6b6b6b);
  /* flex centring keeps the small separators on the text's vertical middle */
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: 0 0.6em;
}

/* Links read as plain text until hovered */
.home-stats a {
  color: inherit;
  text-decoration: none;
}

.home-stats a:hover {
  text-decoration: underline;
}

.home-stats-separator {
  font-size: 0.6em;
  line-height: 1;
}
</style>
