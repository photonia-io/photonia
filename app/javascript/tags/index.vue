<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Tags</h1>
      <hr class="mt-2 mb-4">
      <SectionRow title="Most used" :title-size="5" :grid="false">
        <div class="field is-grouped is-grouped-multiline">
          <TagWithCount
            v-for="tag in result?.mostUsedUserTags"
            :tag="tag"
            :key="tag.id"
          />
        </div>
      </SectionRow>
      <SectionRow title="Least used" :title-size="5" :grid="false">
        <div class="field is-grouped is-grouped-multiline">
          <TagWithCount
            v-for="tag in result?.leastUsedUserTags"
            :tag="tag"
            :key="tag.id"
          />
        </div>
      </SectionRow>
      <SectionRow title="Most used AI tags" :title-size="5" :grid="false">
        <div class="field is-grouped is-grouped-multiline">
          <TagWithCount
            v-for="tag in result?.mostUsedMachineTags"
            :tag="tag"
            :key="tag.id"
          />
        </div>
      </SectionRow>
      <SectionRow title="Least used AI tags" :title-size="5" :grid="false">
        <div class="field is-grouped is-grouped-multiline">
          <TagWithCount
            v-for="tag in result?.leastUsedMachineTags"
            :tag="tag"
            :key="tag.id"
          />
        </div>
      </SectionRow>
    </div>
  </section>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import SectionRow from '@/homepage/section-row.vue'
  import TagWithCount from '@/tag-with-count.vue'

  useTitle('Tags')

  const { result } = useQuery(gql`${gql_queries.tags_index}`)
</script>

<style>

</style>
