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

const emptyAlbum = {
        title: '',
        photos: []
      }

const queryString = gql_queries.albums_show
const GQLQuery = gql`${queryString}`
const { result } = useQuery(GQLQuery, { id: route.params.id })

const album = computed(() => result.value?.album ?? emptyAlbum)
const title = computed(() => `Album: ${album.value.title}`)

useTitle(title)
</script>

<style>

</style>
