<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">{{ page.title }}</h1>
      <hr class="mt-2 mb-4" />
      <div class="content" v-html="page.content"></div>
    </div>
  </section>
</template>

<script setup>
import { ref, computed } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useRoute } from "vue-router";

const emptyPage = {
  title: "Loading...",
  content: "Loading...",
};

const route = useRoute();
const routeName = computed(() => route.name);

const { result, loading } = useQuery(
  gql`
    query PageQuery($id: ID!) {
      page(id: $id) {
        title
        content
      }
    }
  `,
  { id: routeName },
);

const page = computed(() => result.value?.page ?? emptyPage);
const title = computed(() => `${page.value.title}`);
useTitle(title);
</script>

<style></style>
