<template>
  <a class="tag is-delete is-danger" title="Delete tag" @click="deleteTag"></a>
</template>

<script setup>
import { defineProps } from "vue";

const props = defineProps({
  tag: {
    type: Object,
    required: true,
  },
  photoId: {
    type: String,
    required: true,
  },
});

const deleteTag = () => {
  // Implement tag deletion logic here
};
</script>
