<template>
  <DisplayHero
    v-if="!loading"
    :photo="result.latestPhoto"
  />
  <section class="section-pt-pb-0">
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
    <hr class="mt-1 mb-4">
    <div class="block">
      <div class="columns">
        <div class="column is-half">
          <RandomPhotos
            v-if="result && result.randomPhotos"
            :photos="result.randomPhotos"
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
  </section>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import DisplayHero from '../photos/display-hero.vue'
  import RandomPhotos from './random-photos.vue'
  import MostUsedTags from './most-used-tags.vue'

  useTitle('')

  const { result, loading } = useQuery(gql`${gql_queries.homepage_index}`)
</script>
