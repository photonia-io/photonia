<template>
  <h2 class="title is-3 mb-2">Most used tags</h2>
  <hr class="mt-0 mb-3"/>
  <div class="field is-grouped is-grouped-multiline">
    <TagWithCount
      v-for="tag in tags"
      :tag="tag"
      :key="tag.id"
    />
  </div>
  <router-link :to="{ name: 'tags-index' }" class="button">See tags page...</router-link>
</template>

<script>
  import TagWithCount from '../tag-with-count.vue'

  export default {
    name: 'MostUsedTags',
    components: {
      TagWithCount
    },
    props: [ 'tags' ]
  }
</script>
