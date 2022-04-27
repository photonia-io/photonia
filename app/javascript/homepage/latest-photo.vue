<template>
  <div>
    <h1 class="title">Latest photo</h1>
      <router-link v-if="photo.id != ''" :to="{ name: 'photos-show', params: { id: photo.id } }">
        <img :src="photo.extralargeImageUrl" class="image is-fullwidth" />
      </router-link>
      <div class="level mt-3">
        <div class="level-left">
          <router-link v-if="photo.id != ''" :to="{ name: 'photos-show', params: { id: photo.id } }">
            <span class="title is-5">{{ photo.name }}</span>
          </router-link>
        </div>
        <div class="level-right">
          <router-link :to="{ name: 'photos-index' }" class="button">
            See all photos...
          </router-link>
        </div>
      </div>
  </div>
</template>

<script>
  export default {
    name: 'LatestPhoto',
    props: [ 'photo' ],
  }
</script>
