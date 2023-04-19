<template>
  <h1 class="title is-3">Random Photos</h1>
  <div class="columns is-variable is-multiline">
    <div
      v-for="photo in photos"
      class="column is-half"
    >
      <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
        <img
          v-if="photo.intelligentOrSquareMediumImageUrl"
          :src="photo.intelligentOrSquareMediumImageUrl"
          class="image is-fullwidth"
        />
        <ImagePlaceholder
          v-else
        />
        {{ photo.name }}
      </router-link>
    </div>
  </div>
</template>

<script setup>
  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })
</script>
