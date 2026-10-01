<template>
  <SectionRow title="Browse by year" :grid="false">
    <div class="field is-grouped is-grouped-multiline">
      <div v-for="entry in years" :key="entry.year" class="control">
        <div class="tags has-addons">
          <router-link :to="yearRoute(entry.year)" class="tag is-soft">
            {{ entry.year }}
          </router-link>
          <span class="tag">{{ entry.count }}</span>
        </div>
      </div>
    </div>
  </SectionRow>
</template>

<script setup>
import SectionRow from "./section-row.vue";

defineProps({
  // [{ year, count }], newest first
  years: { type: Array, required: true },
});

// Opens the advanced search on that calendar year (inclusive dates).
const yearRoute = (year) => ({
  name: "photos-search",
  query: { takenFrom: `${year}-01-01`, takenTo: `${year}-12-31` },
});
</script>
