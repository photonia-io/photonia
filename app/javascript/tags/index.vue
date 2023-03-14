<template>
  <div>
    <h1 class="title">Tags</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <h2 class="title is-4">Most used</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount
        v-if="result && result.mostUsedUserTags"
        v-for="tag in result.mostUsedUserTags"
        :tag="tag"
        :key="tag.id"
      />
    </div>
    <h2 class="title is-4">Least used</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount
        v-if="result && result.leastUsedUserTags"
        v-for="tag in result.leastUsedUserTags"
        :tag="tag"
        :key="tag.id"
      />
    </div>
    <h2 class="title is-4">Most used AI tags</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount
        v-if="result && result.mostUsedMachineTags"
        v-for="tag in result.mostUsedMachineTags"
        :tag="tag"
        :key="tag.id"
      />
    </div>
    <h2 class="title is-4">Least used AI tags</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount
        v-if="result && result.leastUsedMachineTags"
        v-for="tag in result.leastUsedMachineTags"
        :tag="tag"
        :key="tag.id"
      />
    </div>
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import TagWithCount from '../tag-with-count.vue'

  useTitle('Tags')

  const { result } = useQuery(gql`${gql_queries.tags_index}`)
</script>

<style>

</style>
