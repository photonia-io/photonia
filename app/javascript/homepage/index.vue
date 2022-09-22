<template>
  <div>
    <div class="block">
      <span v-if="$apollo.loading">Loading...</span>
      <LatestPhoto v-else :photo="latestPhoto"/>
    </div>
    <hr class="is-hidden-touch mt-1 mb-4">
    <div class="block">
      <div class="columns">
        <div class="column is-half">
          <RandomPhoto :photo="randomPhoto"/>
        </div>
        <div class="column is-half">
          <MostUsedTags :tags="mostUsedTags"/>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import gql from 'graphql-tag'
  import LatestPhoto from './latest-photo'
  import RandomPhoto from './random-photo'
  import MostUsedTags from './most-used-tags'
  import writeGQLQuery from '../mixins/write-gql-query'

  const queryString = gql_queries.homepage_index
  const GQLQuery = gql`${queryString}`

  export default {
    name: 'Homepage',
    components: {
      LatestPhoto,
      RandomPhoto,
      MostUsedTags
    },
    mixins: [writeGQLQuery(queryString, GQLQuery)],
    data () {
      return {
        latestPhoto: {
          name: '',
          id: ''
        },
        randomPhoto: {
          name: '',
          id: ''
        },
        mostUsedTags: [],
      }
    },
    apollo: {
      homepage: {
        query: GQLQuery,
        update: function(data) {
          this.latestPhoto = data.latestPhoto
          this.randomPhoto = data.randomPhoto
          this.mostUsedTags = data.mostUsedTags
        }
      }
    }
  }
</script>
