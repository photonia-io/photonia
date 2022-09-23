<template>
  <div>
    <h1 class="title">Tags</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <h2 class="title is-4">Most used</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount v-for="tag in mostUsedUserTags" :tag="tag" :key="tag.id" />
    </div>
    <h2 class="title is-4">Least used</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount v-for="tag in leastUsedUserTags" :tag="tag" :key="tag.id" />
    </div>
    <h2 class="title is-4">Most used AI tags</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount v-for="tag in mostUsedMachineTags" :tag="tag" :key="tag.id" />
    </div>
    <h2 class="title is-4">Least used AI tags</h2>
    <div class="field is-grouped is-grouped-multiline mb-2">
      <TagWithCount v-for="tag in leastUsedMachineTags" :tag="tag" :key="tag.id" />
    </div>
  </div>
</template>

<script>
import writeGQLQuery from '../mixins/write-gql-query'
import gql from 'graphql-tag'

import TagWithCount from '../tag-with-count.vue'

const queryString = gql_queries.tags_index
const GQLQuery = gql`${queryString}`

export default {
  name: 'TagsIndex',
  pageTitle: 'Tags - Photonia',
  components: {
    TagWithCount
  },
  mixins: [writeGQLQuery(queryString, GQLQuery)],
  data () {
    return {
      mostUsedUserTags: [],
      leastUsedUserTags: [],
      mostUsedMachineTags: [],
      leastUsedMachineTags: []
    }
  },
  apollo: {
    x: {
      query: GQLQuery,
      update: function(data) {
        this.mostUsedUserTags = data.mostUsedUserTags
        this.leastUsedUserTags = data.leastUsedUserTags
        this.mostUsedMachineTags = data.mostUsedMachineTags
        this.leastUsedMachineTags = data.leastUsedMachineTags
      }
    }
  }
}
</script>

<style>

</style>
