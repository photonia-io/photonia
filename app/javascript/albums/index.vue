<template>
  <div>
    <h1 class="title">Albums</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <AlbumItem
        v-for="album in albums"
        :album="album"
        :key="album.id"
      />
    </div>
  </div>
</template>

<script>
  import gql from 'graphql-tag'
  import AlbumItem from './album-item'
  import writeGQLQuery from '../mixins/write-gql-query'

  const queryString = gql_queries.albums_index
  const GQLQuery = gql`${queryString}`

  export default {
    name: 'AlbumsIndex',
    pageTitle: 'Albums - Photonia',
    components: {
      AlbumItem
    },
    mixins: [writeGQLQuery(queryString, GQLQuery)],
    data () {
      return {
        albums: []
      }
    },
    apollo: {
      albums: {
        query: GQLQuery
      }
    }
  }
</script>
