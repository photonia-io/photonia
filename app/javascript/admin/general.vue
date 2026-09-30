<template>
  <div>
    <div class="card">
      <div class="card-content">
        <form @submit.prevent="submit">
          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Site Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    placeholder="Site Name"
                    v-model="siteName"
                  />
                </div>
              </div>
            </div>
          </div>
          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Site Description</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    placeholder="Site Description"
                    v-model="siteDescription"
                  />
                </div>
              </div>
            </div>
          </div>
          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Site Tracking Code</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <textarea
                    class="textarea"
                    placeholder="Site Tracking Code"
                    v-model="siteTrackingCode"
                  ></textarea>
                </div>
              </div>
            </div>
          </div>
          <h3 class="title is-5 mt-5 mb-0">Social Logins</h3>
          <hr class="mt-2 mb-4" />
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Continue with Google</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input
                      type="checkbox"
                      v-model="continueWithGoogleEnabled"
                    />
                    Enabled
                  </label>
                </div>
              </div>
            </div>
          </div>
          <div class="field is-horizontal">
            <div class="field-label">
              <label class="label">Continue with Facebook</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input
                      type="checkbox"
                      v-model="continueWithFacebookEnabled"
                    />
                    Enabled
                  </label>
                </div>
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

useTitle("Admin - General");

const applicationStore = useApplicationStore();

const newSiteName = ref(null);
const newSiteDescription = ref(null);
const newSiteTrackingCode = ref(null);
const newContinueWithGoogleEnabled = ref(null);
const newContinueWithFacebookEnabled = ref(null);
const showReloadButton = ref(false);

const ADMIN_SETTINGS_QUERY = gql`
  query AdminGeneralSettingsQuery {
    adminSettings {
      id
      siteName
      siteDescription
      siteTrackingCode
      continueWithGoogleEnabled
      continueWithFacebookEnabled
    }
  }
`;

const { result } = useQuery(ADMIN_SETTINGS_QUERY);

const siteName = computed({
  get: () => result.value?.adminSettings.siteName,
  set: (value) => {
    newSiteName.value = value;
  },
});
const siteDescription = computed({
  get: () => result.value?.adminSettings.siteDescription,
  set: (value) => {
    newSiteDescription.value = value;
  },
});
const siteTrackingCode = computed({
  get: () => result.value?.adminSettings.siteTrackingCode,
  set: (value) => {
    newSiteTrackingCode.value = value;
  },
});
const continueWithGoogleEnabled = computed({
  get: () => result.value?.adminSettings.continueWithGoogleEnabled,
  set: (value) => {
    newContinueWithGoogleEnabled.value = value;
  },
});
const continueWithFacebookEnabled = computed({
  get: () => result.value?.adminSettings.continueWithFacebookEnabled,
  set: (value) => {
    newContinueWithFacebookEnabled.value = value;
  },
});

// Warns before switching tabs or navigating away with unsaved changes, via
// the same router guard the photo/album/comment editors use. Compares
// against the saved value, not just "was touched" - reverting a field to
// its original value isn't an unsaved change.
const dirty = computed(() =>
  [
    [newSiteName.value, result.value?.adminSettings.siteName],
    [newSiteDescription.value, result.value?.adminSettings.siteDescription],
    [newSiteTrackingCode.value, result.value?.adminSettings.siteTrackingCode],
    [newContinueWithGoogleEnabled.value, result.value?.adminSettings.continueWithGoogleEnabled],
    [newContinueWithFacebookEnabled.value, result.value?.adminSettings.continueWithFacebookEnabled],
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
      $siteName: String
      $siteDescription: String
      $siteTrackingCode: String
      $continueWithGoogleEnabled: Boolean
      $continueWithFacebookEnabled: Boolean
    ) {
      updateAdminSettings(
        siteName: $siteName
        siteDescription: $siteDescription
        siteTrackingCode: $siteTrackingCode
        continueWithGoogleEnabled: $continueWithGoogleEnabled
        continueWithFacebookEnabled: $continueWithFacebookEnabled
      ) {
        id
        siteName
        siteDescription
        siteTrackingCode
        continueWithGoogleEnabled
        continueWithFacebookEnabled
      }
    }
  `,
  () => ({
    variables: {
      siteName: newSiteName.value !== null ? newSiteName.value : siteName.value,
      siteDescription:
        newSiteDescription.value !== null
          ? newSiteDescription.value
          : siteDescription.value,
      siteTrackingCode:
        newSiteTrackingCode.value !== null
          ? newSiteTrackingCode.value
          : siteTrackingCode.value,
      continueWithGoogleEnabled:
        newContinueWithGoogleEnabled.value !== null
          ? newContinueWithGoogleEnabled.value
          : continueWithGoogleEnabled.value,
      continueWithFacebookEnabled:
        newContinueWithFacebookEnabled.value !== null
          ? newContinueWithFacebookEnabled.value
          : continueWithFacebookEnabled.value,
    },
  }),
);

onDone(({ data }) => {
  newSiteName.value = null;
  newSiteDescription.value = null;
  newSiteTrackingCode.value = null;
  newContinueWithGoogleEnabled.value = null;
  newContinueWithFacebookEnabled.value = null;
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
