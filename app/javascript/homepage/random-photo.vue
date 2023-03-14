<template>
  <div>
    <h1 class="title is-3">Random photo</h1>
    <router-link v-if="photo.id != ''" :to="{ name: 'photos-show', params: { id: photo.id } }">
      <img :src="photo.largeImageUrl" class="image is-fullwidth" />
      {{ photo.name }}
    </router-link>
  </div>
</template>

<script>
  export default {
    name: 'RandomPhoto',
    props: [ 'photo' ]
  }
</script>
