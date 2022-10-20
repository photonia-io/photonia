<template>
  <div>
    <h1 class="title">Tag: {{ tag.name }}</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-for="photo in tag.photos"
        :photo="photo"
        :key="photo.id"
      />
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue'
  import { useRoute } from 'vue-router'
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import PhotoItem from '../photos/photo-item'

  // route
  const route = useRoute()

  const emptyTag = {
          name: '',
          photos: []
        }

  const id = computed(() => route.params.id)
  const { result, loading } = useQuery(gql`${gql_queries.tags_show}`, { id: id })

  const tag = computed(() => result.value?.tag ?? emptyTag)
  const title = computed(() => `Album: ${tag.value.name}`)

  useTitle(title)
</script>

<style>

</style>
