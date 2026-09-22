<template>
  <div class="control">
    <div class="tags has-addons">
      <router-link :to="{ name: 'tags-show', params: { id: tag.id } }" class="tag is-soft">{{ tag.name }}</router-link>
      <span class="tag">{{ tag.taggingsCount }}</span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'TagWithCount',
    props: [ 'tag' ]
  }
</script>
