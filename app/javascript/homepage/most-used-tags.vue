<template>
  <SectionRow
    title="Most used tags"
    :to="{ name: 'tags-index' }"
    link-label="See tags page..."
    :grid="false"
  >
    <div class="field is-grouped is-grouped-multiline">
      <TagWithCount v-for="tag in tags" :tag="tag" :key="tag.id" />
    </div>
  </SectionRow>
</template>

<script setup>
import SectionRow from "./section-row.vue";
import TagWithCount from "../tag-with-count.vue";

defineProps({
  tags: { type: Array, required: true },
});
</script>
