<template>
  <div>
    <div class="container">
      <h1 class="title mt-5 mb-1"></h1>
    </div>
    <DisplayHero
      v-if="!loading"
      :photo="result.latestPhoto"
    />
    <div class="container">
      <div
      v-if="!loading"
      class="level mt-3"
    >
      <div class="level-left">
        <span class="title is-5">
          Latest photo:
          <router-link :to="{ name: 'photos-show', params: { id: result.latestPhoto.id } }">
            {{ result.latestPhoto.name }}
          </router-link>          
        </span>
      </div>
      <div class="level-right">
        <router-link :to="{ name: 'photos-index' }" class="button">
          See all photos...
        </router-link>
      </div>
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
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import DisplayHero from '../photos/display-hero.vue'  
  import RandomPhoto from './random-photo.vue'
  import MostUsedTags from './most-used-tags.vue'

  useTitle('')

  const { result, loading } = useQuery(gql`${gql_queries.homepage_index}`)
</script>
