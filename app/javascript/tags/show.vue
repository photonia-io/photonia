<template>
  <div>
    <h1 class="title">Tag: {{ tag.name }}</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1 is-variable is-multiline">
      <PhotoItem
        v-for="photo in tag.photos"
        :photo="photo"
        :key="photo.id"
      />
    </div>
  </div>
</template>

<script>
import gql from 'graphql-tag'
import PhotoItem from '../photos/photo-item'
import writeGQLQuery from '../mixins/write-gql-query'

const queryString = gql_queries.tags_show
const GQLQuery = gql`${queryString}`

export default {
  name: 'TagsShow',
  pageTitle () {
    return `Tag: ${this.tag.name} - Photonia`
  },
  components: {
    PhotoItem,
  },
  mixins: [writeGQLQuery(queryString, GQLQuery)],
  data () {
    return {
      tag: {
        name: '',
        photos: []
      },
    }
  },
  apollo: {
    tag: {
      query: GQLQuery,
      variables () {
        return {
          id: this.$route.params.id
        }
      }
    }
  },
  watch: {
    tag() {
      this.setPageTitle()
    }
  }
}
</script>

<style>

</style>
