<template>
  <div>
    <h1 class="title">Album: {{ album.title }}</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-for="photo in album.photos"
        :photo="photo"
        :key="photo.id"
      />
    </div>
  </div>
</template>

<script>
import gql from 'graphql-tag'
import PhotoItem from '../photos/photo-item'
import writeGQLQuery from '../mixins/write-gql-query'

const queryString = gql_queries.albums_show
const GQLQuery = gql`${queryString}`

export default {
  name: 'AlbumsShow',
  components: {
    PhotoItem,
  },
  mixins: [writeGQLQuery(queryString, GQLQuery)],
  data () {
    return {
      album: {
        title: '',
        photos: []
      },
    }
  },
  apollo: {
    album: {
      query: GQLQuery,
      variables () {
        return {
          id: this.$route.params.id
        }
      }
    }
  },
}
</script>

<style>

</style>
