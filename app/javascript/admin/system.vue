<template>
  <div>
    <div class="card">
      <div class="card-content">
        <form @submit.prevent="submit">
          <h3 class="title is-5 mt-0 mb-0">Rekognition</h3>
          <hr class="mt-2 mb-4" />
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Automatic tagging</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" v-model="rekognitionEnabled" />
                    Enabled
                  </label>
                </div>
                <p class="help">
                  AWS Rekognition, billed per image. Affects new uploads only.
                </p>
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

useTitle("Admin - System");

const applicationStore = useApplicationStore();

const newRekognitionEnabled = ref(null);
const showReloadButton = ref(false);

const ADMIN_SETTINGS_QUERY = gql`
  query AdminSystemSettingsQuery {
    adminSettings {
      id
      rekognitionEnabled
    }
  }
`;

const { result } = useQuery(ADMIN_SETTINGS_QUERY);

const rekognitionEnabled = computed({
  get: () => result.value?.adminSettings.rekognitionEnabled,
  set: (value) => {
    newRekognitionEnabled.value = value;
  },
});

// Warns before switching tabs or navigating away with unsaved changes, via
// the same router guard the photo/album/comment editors use.
// Compares against the saved value, not just "was touched" - toggling back
// to the original value isn't an unsaved change.
const dirty = computed(
  () =>
    newRekognitionEnabled.value !== null &&
    newRekognitionEnabled.value !== result.value?.adminSettings.rekognitionEnabled,
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
    mutation ($rekognitionEnabled: Boolean) {
      updateAdminSettings(rekognitionEnabled: $rekognitionEnabled) {
        id
        rekognitionEnabled
      }
    }
  `,
  () => ({
    variables: {
      rekognitionEnabled:
        newRekognitionEnabled.value !== null
          ? newRekognitionEnabled.value
          : rekognitionEnabled.value,
    },
  }),
);

onDone(({ data }) => {
  newRekognitionEnabled.value = null;
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
