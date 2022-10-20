<template>
  <div>
    <h1 class="title">Albums</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <AlbumItem
        v-if="result && result.albums"
        v-for="album in result.albums"
        :album="album"
        :key="album.id"
      />
    </div>
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import AlbumItem from './album-item'

  useTitle('Albums')

  const queryString = gql_queries.albums_index
  const GQLQuery = gql`${queryString}`
  const { result } = useQuery(GQLQuery)
</script>
