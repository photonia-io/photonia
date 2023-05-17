<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Photos</h1>
          </div>
        </div>
        <div class="level-right">
          <div class="level-item">
            <button
              class="button is-small"
              v-if="userStore.signedIn && !applicationStore.selectionMode"
              @click="applicationStore.enterSelectionMode()"
            >
              Enter Selection Mode
            </button>
          </div>
        </div>
      </div>
      <hr class="mt-2 mb-4">
      <SelectionOptions
        v-if="result && result.photos && userStore.signedIn && applicationStore.selectionMode"
        :photos="result.photos.collection"
      />
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
  </section>
</template>

<script setup>
  import { computed } from 'vue'
  import { useRoute } from 'vue-router'
  import gql from 'graphql-tag'
  import { useTitle } from 'vue-page-title'
  import { useQuery } from '@vue/apollo-composable'
  import { useApplicationStore } from '@/stores/application'
  import { useUserStore } from '@/stores/user'

  // components
  import SelectionOptions from '@/shared/selection-options.vue'
  import PhotoItem from '@/shared/photo-item.vue'
  import Pagination from '@/shared/pagination.vue'

  useTitle('Photos') // todo: add page number

  const route = useRoute()
  const query = computed(() => route.query.q || null)
  const page = computed(() => parseInt(route.query.page) || 1)
  const additionalQueryParams = computed(() => query.value !== null ? { q: query.value } : {})

  const applicationStore = useApplicationStore()
  const userStore = useUserStore()

  const { result } = useQuery(gql`${gql_queries.photos_index}`, { page: page, query: query })
</script>

