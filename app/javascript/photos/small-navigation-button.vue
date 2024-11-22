<template>
  <div class="level-item">
    <router-link
      :to="{ name: 'photos-show', params: { id: props.photo.id } }"
      :class="['button', 'is-light', props.loading ? 'disabled' : '']"
    >
      <span v-if="props.direction === 'left'" class="icon">
        <i class="fas fa-chevron-left"></i>
      </span>
      <span v-if="props.direction === 'left'">Previous</span>
      <img
        :src="props.photo.intelligentOrSquareThumbnailImageUrl"
        class="is-24x24 ml-3"
        :class="[
          'image',
          'is-24x24',
          props.direction === 'left' ? 'ml-3' : 'mr-3',
        ]"
      />
      <span v-if="props.direction === 'right'">Next</span>
      <span v-if="props.direction === 'right'" class="icon">
        <i class="fas fa-chevron-right"></i>
      </span>
    </router-link>
  </div>
</template>

<script setup>
const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  direction: {
    type: String,
    required: true,
  },
  loading: {
    type: Boolean,
    required: true,
  },
});
</script>
