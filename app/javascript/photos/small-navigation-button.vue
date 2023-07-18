<template>
  <div class="level-item">
    <router-link
      :to="{ name: 'photos-show', params: { id: photo.id } }"
      :class="['button', 'is-light', loading ? 'disabled' : '']"
    >
      <span v-if="direction === 'left'" class="icon">
        <i class="fas fa-chevron-left"></i>
      </span>
      <span v-if="direction === 'left'">Previous</span>
      <img
        :src="photo.intelligentOrSquareThumbnailImageUrl"
        class="is-24x24 ml-3"
        :class="['image', 'is-24x24', direction === 'left' ? 'ml-3' : 'mr-3']"
      />
      <span v-if="direction === 'right'">Next</span>
      <span v-if="direction === 'right'" class="icon">
        <i class="fas fa-chevron-right"></i>
      </span>
    </router-link>
  </div>
</template>

<script>
export default {
  props: ["photo", "direction", "loading"],
};
</script>

<style></style>
