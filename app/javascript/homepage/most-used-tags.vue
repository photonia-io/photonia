<template>
  <div>
    <h2 class="title is-3">Most used tags</h2>
    <div class="field is-grouped is-grouped-multiline">
      <TagWithCount
        v-for="tag in tags"
        :tag="tag"
        :key="tag.id"
      />
    </div>
    <router-link :to="{ name: 'tags-index' }" class="button">See tags page...</router-link>
  </div>
</template>

<script>
  import TagWithCount from '../tag-with-count'

  export default {
    name: 'MostUsedTags',
    components: {
      TagWithCount
    },
    props: [ 'tags' ]
  }
</script>
