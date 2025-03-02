<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="title mt-5 mb-0">
        <AlbumTitleEditable
          v-if="canEditAlbum"
          :album="album"
          @update-title="updateAlbumTitle"
        />
        <h1 class="title" v-else>
          {{ title }}
        </h1>
      </div>
      <hr class="mt-2 mb-4" />
      <AlbumDescriptionEditable
        v-if="canEditAlbum"
        :album="album"
        @update-description="updateAlbumDescription"
      />
      <div
        v-else
        class="content"
        v-html="descriptionHtml"
        v-if="album.descriptionHtml"
      />
      <div class="columns is-1 is-multiline" :class="{ 'mt-0': canEditAlbum }">
        <!-- <div class="columns is-1 is-multiline"> -->
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
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "../stores/user";
import toaster from "../mixins/toaster";
import titleHelper from "../mixins/title-helper";
import { descriptionHtmlHelper } from "../mixins/description-helper";

// components
import AlbumTitleEditable from "./album-title-editable.vue";
import AlbumDescriptionEditable from "./album-description-editable.vue";
import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";

// route
const route = useRoute();

const emptyAlbum = {
  title: "",
  photos: [],
};

const userStore = useUserStore();

const id = computed(() => route.params.id);
const page = computed(() => parseInt(route.query.page) || 1);

const { result, loading } = useQuery(
  gql`
    ${gql_queries.albums_show}
  `,
  { id: id, page: page },
);

const album = computed(() => result.value?.album ?? emptyAlbum);

const title = computed(() => `Album: ${titleHelper(album, loading)}`);
useTitle(title);

const canEditAlbum = computed(
  () => !loading.value && userStore.signedIn && album.value.canEdit,
);

const descriptionHtml = computed(() => descriptionHtmlHelper(album, loading));

const {
  mutate: updateAlbumTitle,
  onDone: onUpdateTitleDone,
  onError: onUpdateTitleError,
} = useMutation(gql`
  mutation ($id: String!, $title: String!) {
    updateAlbumTitle(id: $id, title: $title) {
      id
      title
    }
  }
`);

const {
  mutate: updateAlbumDescription,
  onDone: onUpdateDescriptionDone,
  onError: onUpdateDescriptionError,
} = useMutation(gql`
  mutation ($id: String!, $description: String!) {
    updateAlbumDescription(id: $id, description: $description) {
      id
      description
    }
  }
`);

onUpdateTitleDone(({ data }) => {
  toaster("The title has been updated");
});

onUpdateTitleError((error) => {
  toaster(
    "An error occurred while updating the title: " + error.message,
    "is-danger",
  );
});

onUpdateDescriptionDone(({ data }) => {
  toaster("The description has been updated");
});

onUpdateDescriptionError((error) => {
  toaster(
    "An error occurred while updating the description: " + error.message,
    "is-danger",
  );
});
</script>

<style></style>
