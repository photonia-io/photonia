<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Tag: {{ tag.name }}</h1>
      <hr class="mt-2 mb-4" />
      <div class="tags mb-4 is-size-6" v-if="tag.relatedTags.length > 0">
        Related Tags:
        <router-link
          v-for="relatedTag in tag.relatedTags"
          :key="relatedTag.id"
          :to="{ name: 'tags-show', params: { id: relatedTag.id } }"
          class="tag is-info is-light"
        >
          {{ relatedTag.name }}
        </router-link>
      </div>
      <div class="columns is-1 is-multiline">
        <PhotoItem
          v-for="photo in tag.photos.collection"
          :photo="photo"
          :key="photo.id"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="tag.photos.metadata"
        :metadata="tag.photos.metadata"
        :routeParams="{ id: id }"
        routeName="tags-show"
      />
    </div>
  </section>
</template>

<script setup>
import { computed } from "vue";
import { useRoute } from "vue-router";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";

// components
import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";
import GqlQueries from "@/shared/gql_queries.js";

// route
const route = useRoute();

const emptyTag = {
  name: "",
  photos: [],
  relatedTags: [],
};

const id = computed(() => route.params.id);
const page = computed(() => parseInt(route.query.page) || 1);
const { result, loading } = useQuery(
  gql`
    ${GqlQueries.tags_show}
  `,
  { id: id, page: page },
);

const tag = computed(() => result.value?.tag ?? emptyTag);
const title = computed(() => `Tag: ${tag.value.name}`);

useTitle(title);
</script>

<style></style>
