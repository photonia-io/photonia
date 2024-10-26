<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Albums</h1>
      <hr class="mt-2 mb-4" />
      <div class="columns is-1 is-multiline">
        <AlbumItem
          v-if="result && result.albums"
          v-for="album in result.albums.collection"
          :album="album"
          :key="album.id"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="result && result.albums"
        :metadata="result.albums.metadata"
        routeName="albums-index"
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
import AlbumItem from "@/albums/album-item.vue";
import Pagination from "@/shared/pagination.vue";

useTitle("Albums"); // todo: add page number

const route = useRoute();
const page = computed(function () {
  return parseInt(route.query.page) || 1;
});
const { result } = useQuery(
  gql`
    ${gql_queries.albums_index}
  `,
  { page: page },
);
</script>
