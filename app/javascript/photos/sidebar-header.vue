<template>
  <span class="icon-text">
    <span class="icon"><i :class="icon"></i></span>
    <span>{{ title }}</span>
  </span>
</template>

<script setup>
const props = defineProps({
  icon: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
});
</script>
