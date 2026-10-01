<template>
  <section class="home-section mb-5">
    <div class="home-section-header">
      <h2 :class="`title is-${titleSize} mb-0`">{{ title }}</h2>
      <div class="home-section-actions">
        <slot name="actions" />
        <router-link v-if="to" :to="to" class="button is-small">
          {{ linkLabel }}
        </router-link>
      </div>
    </div>
    <hr class="mt-0 mb-3" />
    <slot name="intro" />
    <div :class="{ 'home-row': grid }">
      <template v-if="loading">
        <div v-for="n in skeletonCount" :key="n" class="home-skeleton">
          <div class="home-skeleton-image" />
          <div class="home-skeleton-caption" />
        </div>
      </template>
      <slot v-else />
    </div>
  </section>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  titleSize: { type: Number, default: 3 },
  to: { type: Object, default: null },
  linkLabel: { type: String, default: "See all..." },
  // false for free-form content (e.g. tag chips) instead of the tile row
  grid: { type: Boolean, default: true },
  // grey placeholder tiles in place of the content, so the row keeps its height
  loading: { type: Boolean, default: false },
  skeletonCount: { type: Number, default: 5 },
});
</script>

<style scoped lang="scss">
.home-section-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1rem;
  padding-bottom: 0.75rem;
}

.home-section-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

// Same geometry as HomeTile: a square image and one line of caption.
.home-skeleton-image {
  aspect-ratio: 1;
  border-radius: 0.3rem;
  background-color: var(--bulma-background, #eee);
}

.home-skeleton-caption {
  height: 1.5em;
}

// Five tiles across on desktop; a horizontal scroll strip below that.
.home-row {
  display: grid;
  gap: 0.75rem;
  grid-auto-flow: column;
  grid-auto-columns: 42%;
  overflow-x: auto;
  scroll-snap-type: x proximity;

  > :deep(*) {
    scroll-snap-align: start;
  }
}

@media (min-width: 1024px) {
  .home-row {
    grid-auto-flow: row;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    grid-auto-columns: auto;
    overflow: visible;
  }
}
</style>
