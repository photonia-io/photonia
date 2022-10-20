<template>
  <div>
    <h1 class="title">Photos</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-if="result && result.photos"
        v-for="photo in result.photos"
        :photo="photo"
        :key="photo.id"
      />
    </div>
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import PhotoItem from './photo-item'

  useTitle('Photos')

  const { result } = useQuery(gql`${gql_queries.photos_index}`)
</script>

