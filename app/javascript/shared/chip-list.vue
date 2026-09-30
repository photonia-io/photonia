<template>
  <div class="chip-list">
    <span v-for="item in items" :key="item" class="tags has-addons mr-1 mb-1">
      <span class="tag">{{ item }}</span>
      <a class="tag is-delete" @click="$emit('remove', item)"></a>
    </span>
  </div>
</template>

<script setup>
defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

defineEmits(["remove"]);
</script>

<style scoped>
.chip-list {
  display: flex;
  flex-wrap: wrap;
}
</style>
