<template>
  <router-link
    :to="{ name: 'tags-show', params: { id: tag.id } }"
    class="tag has-background-grey-lighter"
  ><span v-if="type == 'machine'" class="icon"><i class="fas fa-robot"></i></span>{{ tag.name }}</router-link>
</template>

<script>
export default {
  name: 'Tag',
  props: {
    tag: Object,
    type: {
      type: String,
      default: 'user'
    }
  }
}
</script>

<style>

</style>
