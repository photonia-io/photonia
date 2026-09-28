<template>
  <div>
    <div class="card">
      <div class="card-content">
        <form @submit.prevent="submit">
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Commenting</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" v-model="commentingEnabled" />
                    Enabled
                  </label>
                </div>
                <p class="help">
                  Kill switch for all comments. Existing comments stay visible either way.
                </p>
              </div>
            </div>
          </div>
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Photo comments</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" v-model="photoCommentingEnabled" />
                    Enabled
                  </label>
                </div>
                <p class="help">Allow new comments on photos.</p>
              </div>
            </div>
          </div>
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Album comments</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" v-model="albumCommentingEnabled" />
                    Enabled
                  </label>
                </div>
                <p class="help">Allow new comments on albums.</p>
              </div>
            </div>
          </div>
          <hr />
          <div class="field is-horizontal">
            <div class="field-label">
              <!-- Left empty for spacing -->
            </div>
            <div class="field-body">
              <div class="field">
                <div class="field is-grouped">
                  <div class="control">
                    <button type="submit" class="button is-primary">
                      <span>Save</span>
                    </button>
                  </div>

                  <div class="control">
                    <button
                      class="button is-warning"
                      v-if="showReloadButton"
                      @click.prevent="reloadApplication()"
                    >
                      <span>Reload Application</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onBeforeUnmount } from "vue";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import toaster from "../mixins/toaster";
import { useApplicationStore } from "@/stores/application";

useTitle("Admin - Comments");

const applicationStore = useApplicationStore();

const newCommentingEnabled = ref(null);
const newPhotoCommentingEnabled = ref(null);
const newAlbumCommentingEnabled = ref(null);
const showReloadButton = ref(false);

const ADMIN_SETTINGS_QUERY = gql`
  query AdminCommentsSettingsQuery {
    adminSettings {
      id
      commentingEnabled
      photoCommentingEnabled
      albumCommentingEnabled
    }
  }
`;

const { result } = useQuery(ADMIN_SETTINGS_QUERY);

const commentingEnabled = computed({
  get: () => result.value?.adminSettings.commentingEnabled,
  set: (value) => {
    newCommentingEnabled.value = value;
  },
});
const photoCommentingEnabled = computed({
  get: () => result.value?.adminSettings.photoCommentingEnabled,
  set: (value) => {
    newPhotoCommentingEnabled.value = value;
  },
});
const albumCommentingEnabled = computed({
  get: () => result.value?.adminSettings.albumCommentingEnabled,
  set: (value) => {
    newAlbumCommentingEnabled.value = value;
  },
});

// Warns before switching tabs or navigating away with unsaved changes, via
// the same router guard the photo/album/comment editors use. Compares
// against the saved value, not just "was touched" - toggling back to the
// original value isn't an unsaved change.
const dirty = computed(() =>
  [
    [newCommentingEnabled.value, result.value?.adminSettings.commentingEnabled],
    [newPhotoCommentingEnabled.value, result.value?.adminSettings.photoCommentingEnabled],
    [newAlbumCommentingEnabled.value, result.value?.adminSettings.albumCommentingEnabled],
  ].some(([newValue, savedValue]) => newValue !== null && newValue !== savedValue),
);

watch(dirty, (isDirty) => {
  if (isDirty) {
    applicationStore.startEditing();
  } else {
    applicationStore.stopEditing();
  }
});

onBeforeUnmount(() => {
  applicationStore.stopEditing();
});

const {
  mutate: submit,
  onDone,
  onError,
} = useMutation(
  gql`
    mutation (
      $commentingEnabled: Boolean
      $photoCommentingEnabled: Boolean
      $albumCommentingEnabled: Boolean
    ) {
      updateAdminSettings(
        commentingEnabled: $commentingEnabled
        photoCommentingEnabled: $photoCommentingEnabled
        albumCommentingEnabled: $albumCommentingEnabled
      ) {
        id
        commentingEnabled
        photoCommentingEnabled
        albumCommentingEnabled
      }
    }
  `,
  () => ({
    variables: {
      commentingEnabled:
        newCommentingEnabled.value !== null
          ? newCommentingEnabled.value
          : commentingEnabled.value,
      photoCommentingEnabled:
        newPhotoCommentingEnabled.value !== null
          ? newPhotoCommentingEnabled.value
          : photoCommentingEnabled.value,
      albumCommentingEnabled:
        newAlbumCommentingEnabled.value !== null
          ? newAlbumCommentingEnabled.value
          : albumCommentingEnabled.value,
    },
  }),
);

onDone(({ data }) => {
  newCommentingEnabled.value = null;
  newPhotoCommentingEnabled.value = null;
  newAlbumCommentingEnabled.value = null;
  showReloadButton.value = true;
  toaster("Settings saved");
});

onError((error) => {
  toaster("Error saving settings", "is-danger");
});

const reloadApplication = () => {
  window.location = "/";
};
</script>
