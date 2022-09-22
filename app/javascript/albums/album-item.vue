<template>
  <div class="column is-one-quarter">
    <router-link :to="{ name: 'albums-show', params: { id: album.id } }">
      <img v-if="album.coverPhoto" :src="album.coverPhoto.intelligentOrSquareMediumImageUrl" class="image is-fullwidth" />
      {{ album.title }}
    </router-link> ({{ album.photosCount }} {{ album.photosCount == 1 ? 'photo' : 'photos' }})
  </div>
</template>

<script>
  export default {
    name: 'AlbumItem',
    props: [ 'album' ]
  }
</script>
