<template>
  <div class="column is-one-quarter">
    <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
      <img :src="photo.intelligentOrSquareMediumImageUrl" class="image is-fullwidth" />
      {{ photo.name }}
    </router-link>
  </div>
</template>

<script>
  export default {
    name: 'PhotoItem',
    props: [ 'photo' ]
  }
</script>
