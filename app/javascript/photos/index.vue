<template>
  <div>
    <p>le photo index</p>
    <router-link :to="photos_path + '/29541298843'">
      go to 29541298843
    </router-link>
  </div>
</template>

<script>
  export default {
    data() {
      return {
        root_path: '',
        photos_path: '',
        albums_path: '',
        tags_path: ''
      }
    },
    created() {
      const cj = window.configuration_json
      const cjda = cj.data.attributes
      this.root_path = cjda.root_path
      this.photos_path = cjda.photos_path
      this.albums_path = cjda.albums_path
      this.tags_path = cjda.tags_path
    }
  }
</script>

