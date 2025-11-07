<template>
  <div>
    <DisplayHero
      :photo="photo"
      :loading="loading"
      :labelHighlights="labelHighlights"
      @highlight-label="highlightLabel"
      @un-highlight-label="unHighlightLabel"
    />
    <section class="section-pt-pb-0">
      <div class="container">
        <div class="level mb-4">
          <!-- Photo title and navigation -->
          <div class="level-left is-flex-grow-1">
            <PhotoTitleEditable
              v-if="!loading && canEditPhoto"
              :photo="photo"
              @update-title="updatePhotoTitle"
            />
            <h1 v-else class="title level-item">
              {{ title }}
            </h1>
          </div>
          <div class="level-right">
            <SmallNavigationButton
              v-if="photo.previousPhoto"
              :photo="photo.previousPhoto"
              :loading="loading"
              direction="left"
            />
            <SmallNavigationButton
              v-if="photo.nextPhoto"
              :photo="photo.nextPhoto"
              :loading="loading"
              direction="right"
            />
          </div>
        </div>
        <!-- End photo title and navigation -->
        <div class="block mt-2">
          <div class="columns">
            <div class="column is-three-quarters">
              <!-- Left column -->
              <PhotoDescriptionEditable
                v-if="!loading && canEditPhoto"
                :photo="photo"
                @update-description="updatePhotoDescription"
              />
              <div v-else class="content" v-html="descriptionHtml"></div>

              <PhotoManagement
                v-if="!loading && canEditPhoto"
                :photo="photo"
                @delete-photo="deletePhoto"
              />

              <PhotoComments :photo="photo" :loading="loading" @refresh="refreshPhoto" />

              <div class="columns equal-height-columns">
                <div class="column is-half">
                  <PhotoInfo :photo="photo" :loading="loading" />
                </div>
                <div class="column is-half">
                  <PhotoInfobox>
                    <template #header>
                      <SidebarHeader icon="fas fa-camera" title="EXIF" />
                    </template>
                    <div class="icon-text">
                      <span class="icon"
                        ><i class="fas fa-camera-retro"></i
                      ></span>
                      <span v-if="!loading">
                        <span v-if="photo.exifExists">
                          {{ photo.exifCameraFriendlyName }}
                        </span>
                        <span v-else>
                          <em>No EXIF data available</em>
                        </span>
                      </span>
                    </div>
                    <div class="icon-text">
                      <span class="icon"><i class="fas fa-cog"></i></span>
                      <span v-if="!loading">
                        <span v-if="photo.exifExists">
                          f/{{ photo.exifFNumber }} &middot;
                          {{ photo.exifExposureTime }}s &middot;
                          {{ photo.exifFocalLength }}mm &middot; ISO
                          {{ photo.exifIso }}
                        </span>
                        <span v-else>
                          <em>No EXIF data available</em>
                        </span>
                      </span>
                    </div>
                  </PhotoInfobox>
                </div>
              </div>

              <PhotoInfobox v-if="photo.labels?.length > 0">
                <template #header>Labels</template>
                <div class="tags">
                  <LabelListItem
                    v-for="label in photo.labels"
                    @highlight-label="highlightLabel"
                    @un-highlight-label="unHighlightLabel"
                    :label="label"
                    :hoverable="false"
                    :key="label.id"
                  />
                </div>
                <label class="checkbox">
                  <input type="checkbox" v-model="showLabelsOnHero" />
                  Display labels on the photo
                </label>
              </PhotoInfobox>

              <PhotoInfobox>
                <template #header
                  ><SidebarHeader icon="fas fa-tag" title="Tags"
                /></template>
                <div v-if="canEditPhoto">
                  <div class="field is-grouped is-grouped-multiline tag-gaps">
                    <div
                      class="control"
                      v-for="tag in photo.userTags"
                      :key="tag.id"
                    >
                      <div class="tags has-addons">
                        <Tag :tag="tag" />
                        <RemoveTag :tag="tag" :photoId="photo.id" />
                      </div>
                    </div>
                  </div>
                  <PhotoTagInput v-if="!loading" :photo="photo" />
                </div>
                <div v-else>
                  <div class="tags" v-if="photo.userTags?.length > 0">
                    <Tag
                      v-for="tag in photo.userTags"
                      :key="tag.id"
                      :tag="tag"
                    />
                  </div>
                  <span v-else>
                    <em>There are no user tags for this photo.</em>
                  </span>
                </div>
              </PhotoInfobox>

              <PhotoInfobox>
                <template #header>
                  <SidebarHeader icon="fas fa-robot" title="Machine Tags" />
                </template>
                <div
                  v-if="canEditPhoto"
                  class="field is-grouped is-grouped-multiline tag-gaps"
                >
                  <div
                    class="control"
                    v-for="tag in photo.machineTags"
                    :key="tag.id"
                  >
                    <div class="tags has-addons">
                      <Tag :tag="tag" />
                      <RemoveTag :tag="tag" :photoId="photo.id" />
                    </div>
                  </div>
                </div>
                <div v-else class="tags">
                  <Tag
                    v-for="tag in photo.machineTags"
                    :key="tag.id"
                    :tag="tag"
                    type="machine"
                  />
                </div>
              </PhotoInfobox>
            </div>
            <!-- End left column -->
            <div class="column is-one-quarter">
              <SidebarHeader
                v-if="showAlbumBrowser"
                icon="fas fa-book"
                title="Albums"
              />
              <ul
                v-if="showAlbumBrowser"
                class="block-list is-small has-radius pb-4"
              >
                <li v-for="album in photo.albums" :key="album.id">
                  <h4 class="is-size-6 mb-2">
                    <router-link
                      :to="{ name: 'albums-show', params: { id: album.id } }"
                    >
                      {{ album.title }}
                    </router-link>
                  </h4>
                  <div class="columns is-1 is-mobile">
                    <div class="column is-half">
                      <router-link
                        v-if="album.previousPhotoInAlbum"
                        :to="{
                          name: 'photos-show',
                          params: { id: album.previousPhotoInAlbum.id },
                        }"
                        class="button is-fullwidth is-image-button"
                      >
                        <img
                          :src="
                            album.previousPhotoInAlbum
                              .intelligentOrSquareThumbnailImageUrl
                          "
                          class="image is-fullwidth mb-2"
                        />
                        <span
                          class="icon-text is-hidden-desktop-only is-hidden-tablet-only"
                        >
                          <span class="icon"
                            ><i class="fas fa-chevron-left"></i
                          ></span>
                          <span>Previous</span>
                        </span>
                      </router-link>
                      <button
                        v-else
                        class="button is-fullwidth is-image-button"
                        disabled
                      >
                        <Empty class="mb-2" />
                        <span
                          class="icon-text is-hidden-desktop-only is-hidden-tablet-only"
                        >
                          <span class="icon"
                            ><i class="fas fa-chevron-left"></i
                          ></span>
                          <span>Previous</span>
                        </span>
                      </button>
                    </div>
                    <div class="column is-half">
                      <router-link
                        v-if="album.nextPhotoInAlbum"
                        :to="{
                          name: 'photos-show',
                          params: { id: album.nextPhotoInAlbum.id },
                        }"
                        class="button is-fullwidth is-image-button"
                      >
                        <img
                          :src="
                            album.nextPhotoInAlbum
                              .intelligentOrSquareThumbnailImageUrl
                          "
                          class="image is-fullwidth mb-2"
                        />
                        <span
                          class="icon-text is-hidden-desktop-only is-hidden-tablet-only"
                        >
                          <span>Next</span>
                          <span class="icon"
                            ><i class="fas fa-chevron-right"></i
                          ></span>
                        </span>
                      </router-link>
                      <button
                        v-else
                        class="button is-fullwidth is-image-button"
                        disabled
                      >
                        <Empty class="mb-2" />
                        <span
                          class="icon-text is-hidden-desktop-only is-hidden-tablet-only"
                        >
                          <span>Next</span>
                          <span class="icon"
                            ><i class="fas fa-chevron-right"></i
                          ></span>
                        </span>
                      </button>
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "../stores/user";
import { useApplicationStore } from "@/stores/application";
import toaster from "../mixins/toaster";
import titleHelper from "../mixins/title-helper";
import { descriptionHtmlHelper } from "../mixins/description-helper";

// components
import PhotoTitleEditable from "./photo-title-editable.vue";
import PhotoDescriptionEditable from "./photo-description-editable.vue";
import PhotoManagement from "./photo-management.vue";
import PhotoInfo from "./photo-info.vue";
import PhotoInfobox from "./photo-infobox.vue";
import PhotoComments from "./photo-comments.vue";
import SmallNavigationButton from "@/photos/small-navigation-button.vue";
import DisplayHero from "./display-hero.vue";
import SidebarHeader from "./sidebar-header.vue";
import LabelListItem from "@/photos/label-list-item.vue";
import Tag from "@/tags/tag.vue";
import RemoveTag from "@/tags/remove-tag.vue";
import Empty from "@/empty.vue";
import PhotoTagInput from "./photo-tag-input.vue";

// route & router
const route = useRoute();
const router = useRouter();

const emptyPhoto = {
  title: "",
  description: "",
  largeImageUrl: "",
  previousPhoto: null,
  nextPhoto: null,
  albums: [],
  tags: [],
  rekognitionTags: [],
  labels: null,
};

const id = computed(() => route.params.id);
const { result, loading, refetch } = useQuery(
  gql`
    ${gql_queries.photos_show}
  `,
  { id: id },
);
const labelHighlights = ref({});

const apolloClient = inject("apolloClient");

const {
  mutate: updatePhotoTitle,
  onDone: onUpdateTitleDone,
  onError: onUpdateTitleError,
} = useMutation(gql`
  mutation ($id: String!, $title: String!) {
    updatePhotoTitle(id: $id, title: $title) {
      id
      title
    }
  }
`);

const {
  mutate: updatePhotoDescription,
  onDone: onUpdateDescriptionDone,
  onError: onUpdateDescriptionError,
} = useMutation(gql`
  mutation ($id: String!, $description: String!) {
    updatePhotoDescription(id: $id, description: $description) {
      id
      description
    }
  }
`);

const {
  mutate: deletePhoto,
  onDone: onDeletePhotoDone,
  onError: onDeletePhotoError,
} = useMutation(gql`
  mutation ($id: String!) {
    deletePhoto(id: $id) {
      id
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

onDeletePhotoDone(({ data }) => {
  apolloClient.cache.reset();
  toaster("The photo has been deleted", "is-success");
  router.push({ name: "photos-index" });
});

onDeletePhotoError((error) => {
  // todo console.log(error)
});

const highlightLabel = (label) => {
  labelHighlights.value[label.id] = true;
};

const unHighlightLabel = (label) => {
  labelHighlights.value[label.id] = false;
};

const refreshPhoto = () => {
  refetch();
};

const photo = computed(() => result.value?.photo ?? emptyPhoto);
const canEditPhoto = computed(() => userStore.signedIn && photo.value.canEdit);

const showAlbumBrowser = computed(() => photo.value.albums.length > 0);

const title = computed(() => titleHelper(photo, loading));
useTitle(title);

const descriptionHtml = computed(() => descriptionHtmlHelper(photo, loading));

const userStore = useUserStore();
const applicationStore = useApplicationStore();

const showLabelsOnHero = computed({
  get() {
    return applicationStore.showLabelsOnHero;
  },
  set(value) {
    if (value === true) {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
    applicationStore.showLabelsOnHero = value;
  },
});

onMounted(() => {
  document.addEventListener("keydown", handleKeyDown);
});

onBeforeUnmount(() => {
  document.removeEventListener("keydown", handleKeyDown);
});

const handleKeyDown = (event) => {
  if (applicationStore.navigationShortcutsEnabled === true) {
    if (event.key === "ArrowLeft") {
      navigateToPreviousPhoto();
    } else if (event.key === "ArrowRight") {
      navigateToNextPhoto();
    }
  }
};

const navigateToNextPhoto = () => {
  if (photo.value.nextPhoto) {
    router.push({
      name: "photos-show",
      params: { id: photo.value.nextPhoto.id },
    });
  }
};

const navigateToPreviousPhoto = () => {
  if (photo.value.previousPhoto) {
    router.push({
      name: "photos-show",
      params: { id: photo.value.previousPhoto.id },
    });
  }
};
</script>

<style scoped>
.message-body .tags {
  margin-bottom: 0.2em;
}

.equal-height-columns .message {
  height: 100%;
}

.tag-gaps {
  row-gap: 0.5em;
  column-gap: 0.5em;
}
</style>
