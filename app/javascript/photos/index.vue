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
      :additionalQueryParams="additionalQueryParams"
      routeName="photos-index"
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
  import PhotoItem from '@/shared/photo-item.vue'
  import Pagination from '@/shared/pagination.vue'

  useTitle('Photos') // todo: add page number

  const route = useRoute()
  const query = computed(() => route.query.q || null)
  const page = computed(() => parseInt(route.query.page) || 1)
  const additionalQueryParams = computed(() => query.value !== null ? { q: query.value } : {})
  const { result } = useQuery(gql`${gql_queries.photos_index}`, { page: page, query: query })
</script>

