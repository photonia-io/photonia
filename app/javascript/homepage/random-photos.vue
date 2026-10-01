<template>
  <SectionRow v-if="showing" title="Random Photos" :loading="busy">
    <template #actions>
      <button
        type="button"
        class="button is-small"
        :class="{ 'is-loading': busy }"
        :disabled="busy"
        @click="shuffle"
      >
        Shuffle
      </button>
    </template>
    <HomeTile
      v-for="photo in photos"
      :key="photo.id"
      :to="{ name: 'photos-show', params: { id: photo.id } }"
      :title="photo.title"
      :image-url="photo.intelligentOrSquareMediumImageUrl"
    />
  </SectionRow>
</template>

<script setup>
import { computed, ref } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

import SectionRow from "./section-row.vue";
import HomeTile from "./home-tile.vue";

const { result, loading, refetch } = useQuery(
  gql`${gql_queries.homepage_random_photos}`,
);

const photos = computed(() => result.value?.randomPhotos?.collection ?? []);

// refetch() doesn't reliably flip `loading`, so track the shuffle ourselves.
const shuffling = ref(false);
const busy = computed(() => loading.value || shuffling.value);
const showing = computed(() => busy.value || photos.value.length > 0);

const shuffle = async () => {
  shuffling.value = true;
  try {
    await refetch();
  } finally {
    shuffling.value = false;
  }
};
</script>
