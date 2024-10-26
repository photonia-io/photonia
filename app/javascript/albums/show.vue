<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Album: {{ album.title }}</h1>
      <hr class="mt-2 mb-4" />
      <div
        class="content"
        v-html="album.descriptionHtml"
        v-if="album.descriptionHtml"
      />
      <div class="columns is-1 is-multiline">
        <PhotoItem
          v-for="photo in album.photos.collection"
          :photo="photo"
          :key="photo.id"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="album.photos.metadata"
        :metadata="album.photos.metadata"
        :routeParams="{ id: id }"
        routeName="albums-show"
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

// route
const route = useRoute();

const emptyAlbum = {
  title: "",
  photos: [],
};

const id = computed(() => route.params.id);
const page = computed(() => parseInt(route.query.page) || 1);

const { result } = useQuery(
  gql`
    ${gql_queries.albums_show}
  `,
  { id: id, page: page },
);

const album = computed(() => result.value?.album ?? emptyAlbum);
const title = computed(() => `Album: ${album.value.title}`);

useTitle(title);
</script>

<style></style>
