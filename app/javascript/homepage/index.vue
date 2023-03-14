<template>
  <div>
    <div class="block">
      <LatestPhoto
        v-if="result && result.latestPhoto"
        :photo="result.latestPhoto"
      />
    </div>
    <hr class="is-hidden-touch mt-1 mb-4">
    <div class="block">
      <div class="columns">
        <div class="column is-half">
          <RandomPhoto
            v-if="result && result.randomPhoto"
            :photo="result.randomPhoto"
          />
        </div>
        <div class="column is-half">
          <MostUsedTags
            v-if="result && result.mostUsedTags"
            :tags="result.mostUsedTags"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import LatestPhoto from './latest-photo'
  import RandomPhoto from './random-photo'
  import MostUsedTags from './most-used-tags'

  useTitle('')

  const { result } = useQuery(gql`${gql_queries.homepage_index}`)
</script>
