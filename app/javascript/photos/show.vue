<template>
  <div>
    <ThumbnailEditor
      v-if="thumbnailEditMode"
      :photo="photo"
      :edit-mode="thumbnailEditMode"
      @save="saveThumbnail"
      @cancel="cancelThumbnailEdit"
    />
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
              :query="navigationQuery"
              direction="left"
            />
            <SmallNavigationButton
              v-if="photo.nextPhoto"
              :photo="photo.nextPhoto"
              :loading="loading"
              :query="navigationQuery"
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
                @edit-thumbnail="startThumbnailEdit"
              />

              <PhotoComments :photo="photo" :loading="loading" @refresh="refreshPhoto" />

              <div class="columns equal-height-columns">
                <div class="column is-half">
                  <PhotoInfo
                    ref="photoInfoRef"
                    :photo="photo"
                    :loading="loading"
                    :can-edit="canEditPhoto"
                    @update-privacy="setPhotoPrivacy"
                    @update-taken-at="setPhotoTakenAt"
                    @reset-taken-at="resetPhotoTakenAt"
                    @update-license="setPhotoLicense"
                  />
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
                  <PhotoTagInput
                    v-if="!loading"
                    :user-tags="photo.userTags || []"
                    :machine-tags="photo.machineTags || []"
                    :is-adding-tag="isAddingTag"
                    @add-tag="handleAddTag"
                  />
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
                v-if="photo.albums?.length"
                class="block-list is-small has-radius mt-2"
              >
                <li
                  v-for="album in photo.albums"
                  :key="album.id"
                  :class="{ 'is-navigating': album.id === inAlbumId }"
                >
                  <h4 class="is-size-6 mb-2 is-flex is-align-items-baseline">
                    <router-link :to="albumRoute(album)" class="album-title">
                      {{ album.title }}
                    </router-link>
                    <span
                      v-if="album.photoPositionInAlbum"
                      class="is-size-7 has-text-weight-normal is-flex-shrink-0 ml-2"
                    >
                      {{ album.photoPositionInAlbum.position }} /
                      {{ album.photoPositionInAlbum.total }}
                    </span>
                    <button
                      v-if="canEditPhoto"
                      class="album-remove is-size-7 is-flex-shrink-0 ml-2"
                      :title="`Remove this photo from ${album.title}`"
                      @click="confirmRemoveFromAlbum(album)"
                    >
                      <i class="fas fa-folder-minus"></i>
                    </button>
                  </h4>
                  <div class="columns is-1 is-mobile">
                    <div class="column is-half">
                      <router-link
                        v-if="album.previousPhotoInAlbum"
                        :to="{
                          name: 'photos-show',
                          params: { id: album.previousPhotoInAlbum.id },
                          query: navigationQuery,
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
                          query: navigationQuery,
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
                  <!-- Keyboard-only, so there is nothing to offer on touch -->
                  <div class="album-navigation is-hidden-touch">
                    <template v-if="album.id === inAlbumId">
                      <p class="help mt-0 mb-2">
                        You can navigate in this album by using the
                        <strong>J</strong> / <strong>K</strong> keys
                      </p>
                      <button
                        class="button is-small is-fullwidth"
                        @click="stopNavigatingAlbum()"
                      >
                        <span class="icon"><i class="fas fa-times"></i></span>
                        <span>Stop navigating this album</span>
                      </button>
                    </template>
                    <button
                      v-else
                      class="button is-small is-fullwidth"
                      @click="startNavigatingAlbum(album.id)"
                    >
                      <span class="icon"><i class="fas fa-keyboard"></i></span>
                      <span>Navigate this album</span>
                    </button>
                  </div>
                </li>
              </ul>
              <p v-else-if="canEditPhoto" class="mt-2 mb-3">
                <em>This photo is not in an album yet.</em>
              </p>
              <AddToAlbumButton
                v-if="canEditPhoto"
                :photos="[photo]"
                button-class="is-fullwidth"
                label="Add Photo to an Album"
                @add-photos-to-album="addPhotosToAlbum"
                @create-album-with-photos="createAlbumWithPhotos"
              />
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Remove from album confirmation -->
    <teleport to="#modal-root">
      <div :class="['modal', removeFromAlbumModalActive ? 'is-active' : null]">
        <div class="modal-background"></div>
        <div class="modal-card" ref="removeFromAlbumModalCard" tabindex="-1">
          <header class="modal-card-head">
            <p class="modal-card-title has-text-centered">Remove From Album</p>
          </header>
          <div class="modal-card-body">
            <p>
              Remove this photo from
              <strong>{{ albumToRemoveFrom?.title }}</strong>? The photo itself
              is not deleted.
            </p>
          </div>
          <footer class="modal-card-foot is-justify-content-center">
            <div class="buttons">
              <button class="button is-danger" @click="performRemoveFromAlbum">
                Yes, remove
              </button>
              <button class="button is-info" @click="closeRemoveFromAlbumModal">
                Cancel
              </button>
            </div>
          </footer>
        </div>
      </div>
    </teleport>
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
import {
  isTypingTarget,
  useAlbumNavigation,
} from "../mixins/use-album-navigation";
import { useModal } from "@/mixins/use-modal";

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
import AddToAlbumButton from "@/shared/buttons/add-to-album.vue";
import ThumbnailEditor from "./thumbnail-editor.vue";

// route & router
const route = useRoute();
const router = useRouter();

const id = computed(() => route.params.id);
const { result, loading, refetch } = useQuery(
  gql`
    ${gql_queries.photos_show}
  `,
  { id: id },
  { keepPreviousResult: true },
);
const labelHighlights = ref({});
const isAddingTag = ref(false);

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
  mutate: setPhotoLicense,
  onDone: onSetLicenseDone,
  onError: onSetLicenseError,
} = useMutation(gql`
  mutation ($id: String!, $license: String) {
    setPhotoLicense(id: $id, license: $license) {
      id
      license
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

const {
  mutate: setPhotoPrivacy,
  onDone: onSetPrivacyDone,
  onError: onSetPrivacyError,
} = useMutation(gql`
  mutation ($id: String!, $privacy: String!) {
    setPhotoPrivacy(id: $id, privacy: $privacy) {
      id
      privacy
    }
  }
`);

const {
  mutate: setPhotoTakenAt,
  onDone: onSetTakenAtDone,
  onError: onSetTakenAtError,
} = useMutation(gql`
  mutation (
    $id: String!
    $year: Int!
    $month: Int
    $day: Int
    $hour: Int
    $minute: Int
    $approximate: Boolean
    $scanned: Boolean
  ) {
    setPhotoTakenAt(
      id: $id
      year: $year
      month: $month
      day: $day
      hour: $hour
      minute: $minute
      approximate: $approximate
      scanned: $scanned
    ) {
      id
      scanned
      takenAtInfo {
        year
        month
        day
        hour
        minute
        precision
        source
        approximate
        exifAvailable
      }
    }
  }
`);

const {
  mutate: resetPhotoTakenAt,
  onDone: onResetTakenAtDone,
  onError: onResetTakenAtError,
} = useMutation(gql`
  mutation ($id: String!) {
    resetPhotoTakenAt(id: $id) {
      id
      scanned
      takenAtInfo {
        year
        month
        day
        hour
        minute
        precision
        source
        approximate
        exifAvailable
      }
    }
  }
`);

const {
  mutate: updatePhotoThumbnail,
  onDone: onUpdateThumbnailDone,
  onError: onUpdateThumbnailError,
} = useMutation(gql`
  mutation ($id: String!, $thumbnail: UserThumbnailInput!) {
    updatePhotoThumbnail(id: $id, thumbnail: $thumbnail) {
      id
      userThumbnail {
        top
        left
        width
        height
      }
    }
  }
`);

const {
  mutate: addTagToPhoto,
  onDone: onAddTagDone,
  onError: onAddTagError,
} = useMutation(gql`
  mutation AddTagToPhoto($id: String!, $tagName: String!) {
    addTagToPhoto(id: $id, tagName: $tagName) {
      photo {
        id
        userTags {
          id
          name
        }
      }
      tag {
        id
        name
      }
    }
  }
`);

const {
  mutate: addPhotosToAlbum,
  onDone: onAddPhotosToAlbumDone,
  onError: onAddPhotosToAlbumError,
} = useMutation(gql`
  mutation ($albumId: String!, $photoIds: [String!]!) {
    addPhotosToAlbum(albumId: $albumId, photoIds: $photoIds) {
      errors
      album {
        id
        title
      }
    }
  }
`);

const {
  mutate: createAlbumWithPhotos,
  onDone: onCreateAlbumWithPhotosDone,
  onError: onCreateAlbumWithPhotosError,
} = useMutation(gql`
  mutation ($title: String!, $photoIds: [String!]!) {
    createAlbumWithPhotos(title: $title, photoIds: $photoIds) {
      id
      title
    }
  }
`);

const {
  mutate: removePhotosFromAlbum,
  onDone: onRemovePhotosFromAlbumDone,
  onError: onRemovePhotosFromAlbumError,
} = useMutation(gql`
  mutation ($albumId: String!, $photoIds: [String!]!) {
    removePhotosFromAlbum(albumId: $albumId, photoIds: $photoIds) {
      errors
      album {
        id
        title
      }
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

onSetLicenseDone(({ data }) => {
  toaster("The license has been updated");
});

onSetLicenseError((error) => {
  toaster(
    "An error occurred while updating the license: " + error.message,
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

onSetPrivacyDone(({ data }) => {
  toaster("The privacy has been updated");
});

onSetPrivacyError((error) => {
  toaster(
    "An error occurred while updating the privacy: " + error.message,
    "is-danger",
  );
});

// Template ref to PhotoInfo, so its Date Taken modal can be closed once
// the mutation actually succeeds, rather than closing it optimistically.
const photoInfoRef = ref(null);

onSetTakenAtDone(({ data }) => {
  toaster("The date taken has been updated");
  photoInfoRef.value?.closeTakenAtModal();
});

onSetTakenAtError((error) => {
  toaster(
    "An error occurred while updating the date taken: " + error.message,
    "is-danger",
  );
});

onResetTakenAtDone(({ data }) => {
  toaster("The date taken has been reset");
  photoInfoRef.value?.closeTakenAtModal();
});

onResetTakenAtError((error) => {
  toaster(
    "An error occurred while resetting the date taken: " + error.message,
    "is-danger",
  );
});

onUpdateThumbnailDone(({ data }) => {
  toaster(
    "The thumbnail is being updated in the background. It will soon be available.",
    "is-success",
  );
  thumbnailEditMode.value = false;
  applicationStore.enableNavigationShortcuts();
});

onUpdateThumbnailError((error) => {
  toaster(
    "An error occurred while updating the thumbnail: " + error.message,
    "is-danger",
  );
});

const thumbnailEditMode = ref(false);

const startThumbnailEdit = () => {
  thumbnailEditMode.value = true;
  applicationStore.disableNavigationShortcuts();
  // Scroll to top
  window.scrollTo({ top: 0, behavior: "smooth" });
};

const cancelThumbnailEdit = () => {
  thumbnailEditMode.value = false;
  applicationStore.enableNavigationShortcuts();
};

const saveThumbnail = (thumbnailData) => {
  updatePhotoThumbnail({
    id: photo.value.id,
    thumbnail: thumbnailData,
  });
};

onAddTagDone(({ data }) => {
  isAddingTag.value = false;
  toaster(
    `Tag "${data.addTagToPhoto.tag.name}" added successfully`,
    "is-success",
  );
});

onAddTagError((error) => {
  isAddingTag.value = false;
  toaster(
    "An error occurred while adding the tag: " + error.message,
    "is-danger",
  );
});

const handleAddTag = async (tagName) => {
  isAddingTag.value = true;
  await addTagToPhoto({
    id: photo.value.id,
    tagName: tagName,
  });
};

// Album membership shows up outside this page too (album pages, the photo
// counts on /albums), so drop the cache and pull this photo's albums again.
const albumsChanged = (message) => {
  apolloClient.cache.reset();
  refetch();
  toaster(message, "is-success");
};

const albumError = (action, errors) => {
  toaster(
    `An error occurred while ${action}: ` + (errors?.join(", ") || "Unknown error"),
    "is-danger",
  );
};

onAddPhotosToAlbumDone(({ data }) => {
  const payload = data?.addPhotosToAlbum;
  if (!payload || payload.errors?.length > 0) {
    albumError("adding the photo to the album", payload?.errors);
    return;
  }
  albumsChanged(`The photo was added to '${payload.album?.title || ""}'`);
});

onAddPhotosToAlbumError((error) => {
  albumError("adding the photo to the album", [error.message]);
});

onCreateAlbumWithPhotosDone(({ data }) => {
  albumsChanged(
    `The album '${data?.createAlbumWithPhotos?.title || ""}' was created with this photo`,
  );
});

onCreateAlbumWithPhotosError((error) => {
  albumError("creating the album", [error.message]);
});

const albumToRemoveFrom = ref(null);

const {
  active: removeFromAlbumModalActive,
  modalCard: removeFromAlbumModalCard,
  open: openRemoveFromAlbumModal,
  close: closeRemoveFromAlbumModal,
} = useModal();

const confirmRemoveFromAlbum = (album) => {
  albumToRemoveFrom.value = album;
  openRemoveFromAlbumModal();
};

const performRemoveFromAlbum = () => {
  removePhotosFromAlbum({
    albumId: albumToRemoveFrom.value.id,
    photoIds: [photo.value.id],
  });
  closeRemoveFromAlbumModal();
};

onRemovePhotosFromAlbumDone(({ data }) => {
  const payload = data?.removePhotosFromAlbum;
  if (!payload || payload.errors?.length > 0) {
    albumError("removing the photo from the album", payload?.errors);
    return;
  }
  // The album being navigated with J/K may be the one just left.
  if (payload.album?.id === inAlbumId.value) stopNavigatingAlbum();
  albumsChanged(`The photo was removed from '${payload.album?.title || ""}'`);
});

onRemovePhotosFromAlbumError((error) => {
  albumError("removing the photo from the album", [error.message]);
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

const photo = computed(() => result.value?.photo ?? {});

// False while a navigation is in flight and the retained photo is still the
// outgoing one, i.e. whenever photo's identity disagrees with the route.
const showingCurrentPhoto = computed(() => photo.value.id === id.value);


const canEditPhoto = computed(() => userStore.signedIn && photo.value.canEdit);

// Editors always get the section, even with no albums, because it holds the
// Add To Album button.
const showAlbumBrowser = computed(
  () => photo.value.albums?.length > 0 || canEditPhoto.value,
);

const {
  inAlbumId,
  navigationQuery,
  navigateToPhoto,
  albumRoute,
  startNavigatingAlbum,
  stopNavigatingAlbum,
  navigateToNextPhotoInAlbum,
  navigateToPreviousPhotoInAlbum,
} = useAlbumNavigation(photo);

const title = computed(() => titleHelper(photo));
useTitle(title);

const descriptionHtml = computed(() => descriptionHtmlHelper(photo));

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
  // keepPreviousResult holds the outgoing photo on screen while the next one
  // loads, so its previousPhoto/nextPhoto are stale until the route and the
  // result agree again. Key repeat would otherwise navigate from them.
  if (!showingCurrentPhoto.value) return;
  if (event.ctrlKey || event.metaKey || event.altKey) return;
  if (isTypingTarget(event.target)) return;

  if (applicationStore.navigationShortcutsEnabled === true) {
    if (event.key === "ArrowLeft") {
      navigateToPreviousPhoto();
    } else if (event.key === "ArrowRight") {
      navigateToNextPhoto();
    } else if (event.key === "j") {
      navigateToNextPhotoInAlbum();
    } else if (event.key === "k") {
      navigateToPreviousPhotoInAlbum();
    }
  }
};

const navigateToNextPhoto = () => navigateToPhoto(photo.value.nextPhoto);

const navigateToPreviousPhoto = () =>
  navigateToPhoto(photo.value.previousPhoto);
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

/* Each album sits in its own rounded box, dim until it is the one being
   navigated. The box-shadow thickens the active border without shifting
   the layout the way a wider border would. */
.block-list li {
  border: 1px solid var(--bulma-border-weak);
  /* block-list's own 0.25rem separator is too tight now the boxes are outlined */
  margin-bottom: 0.75rem;
  transition:
    border-color 120ms ease-in-out,
    box-shadow 120ms ease-in-out;
}

.block-list li.is-navigating {
  border-color: var(--bulma-link);
  box-shadow: 0 0 0 1px var(--bulma-link);
}

/* Takes the space the counter beside it does not, truncating rather than
   wrapping a long album title onto a second line. */
.album-title {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Bulma gives .columns:not(:last-child) a block-spacing minus column-gap
   bottom margin - 1.25rem at is-1, far too much in this narrow sidebar. */
.block-list li .columns:not(:last-child) {
  margin-bottom: 0.5rem;
}

/* A bare button, not a .button: the latter's padding and border keep the icon
   off the text baseline that the album title and counter share. */
.album-remove {
  padding: 0;
  border: 0;
  background: none;
  cursor: pointer;
  color: var(--bulma-text-weak);
}

.album-remove:hover {
  color: var(--bulma-danger);
}

/* The sidebar is narrow, so let the button labels wrap */
.album-navigation .button {
  white-space: normal;
  height: auto;
  min-height: 2em;
}
</style>
