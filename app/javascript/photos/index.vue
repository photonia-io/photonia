<template>
  <div>
    <h1 class="title">Photos</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-if="result && result.photos"
        v-for="photo in result.photos.collection"
        :photo="photo"
        :key="photo.id"
      />
    </div>
    <hr class="mt-1 mb-4">
    <Pagination
      v-if="result && result.photos"
      :metadata="result.photos.metadata"
      path="/photos"
    />
  </div>
</template>

<script setup>
  import { computed } from 'vue'
  import { useRoute } from 'vue-router'
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import PhotoItem from './photo-item'
  import Pagination from '../pagination'

  useTitle('Photos') // todo: add page number

  const route = useRoute()
  const page = computed(
    function() {
      console.log('computing page')
      return parseInt(route.query.page) || 1
    }
  )
  const { result } = useQuery(gql`${gql_queries.photos_index}`, { page: page })
</script>

