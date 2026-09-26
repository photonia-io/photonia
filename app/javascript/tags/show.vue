<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Tag: {{ tag.name }}</h1>
          </div>
        </div>
        <div
          class="level-right"
          v-if="userStore.signedIn && userStore.uploader"
        >
          <div class="level-item">
            <p class="selection-hint touch-only">
              <span class="icon"><i class="far fa-hand-pointer"></i></span>
              <span>Long press a photo to start selecting</span>
            </p>
          </div>
        </div>
      </div>
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
import { computed, watch } from "vue";
import { useRoute } from "vue-router";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "@/stores/user";
import { useSelectionStore } from "@/stores/selection";
import { useSelectionContext } from "@/mixins/use-selection-context";

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

const userStore = useUserStore();
const selectionStore = useSelectionStore();
useSelectionContext();

watch(
  () => tag.value.photos?.collection,
  (photos) => selectionStore.setPageCollection(photos || []),
  { immediate: true },
);
</script>

<style></style>
