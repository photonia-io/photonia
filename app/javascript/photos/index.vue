<template>
  <div>
    <h1 class="title">Photos</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-for="photo in photos"
        :photo="photo"
        :key="photo.id"
      />
    </div>
  </div>
</template>

<script>
  import gql from 'graphql-tag'
  import PhotoItem from './photo-item'
  import writeGQLQuery from '../mixins/write-gql-query'

  const queryString = gql_queries.photos_index
  const GQLQuery = gql`${queryString}`

  export default {
    name: 'PhotosIndex',
    components: {
      PhotoItem,
    },
    mixins: [writeGQLQuery(queryString, GQLQuery)],
    data () {
      return {
        photos: []
      }
    },
    apollo: {
      photos: {
        query: GQLQuery
      }
    }
  }
</script>

