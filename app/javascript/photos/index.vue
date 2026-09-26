<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Photos</h1>
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
      <div class="columns is-1 is-multiline">
        <PhotoItem
          v-if="result && result.photos"
          v-for="photo in result.photos.collection"
          :photo="photo"
          :key="photo.id"
        />
      </div>
      <hr class="mt-1 mb-4" />
      <Pagination
        v-if="result && result.photos"
        :metadata="result.photos.metadata"
        :additionalQueryParams="additionalQueryParams"
        routeName="photos-index"
      />
    </div>
  </section>
</template>

<script setup>
import { computed, watch } from "vue";
import { useRoute } from "vue-router";
import gql from "graphql-tag";
import { useTitle } from "vue-page-title";
import { useQuery } from "@vue/apollo-composable";
import { useUserStore } from "@/stores/user";
import { useSelectionStore } from "@/stores/selection";
import { useSelectionContext } from "@/mixins/use-selection-context";

// components
import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";

useTitle("Photos"); // todo: add page number

const route = useRoute();
const query = computed(() => route.query.q || null);
const page = computed(() => parseInt(route.query.page) || 1);
const additionalQueryParams = computed(() =>
  query.value !== null ? { q: query.value } : {},
);

const userStore = useUserStore();
const selectionStore = useSelectionStore();
useSelectionContext();

const { result } = useQuery(
  gql`
    ${gql_queries.photos_index}
  `,
  { page: page, query: query },
);

watch(
  () => result.value?.photos?.collection,
  (photos) => selectionStore.setPageCollection(photos || []),
  { immediate: true },
);
</script>
