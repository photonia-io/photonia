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
          <h3 class="title is-5 mt-5 mb-0">Comments</h3>
          <hr class="mt-2 mb-4" />
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
                  Kill switch for user comments. Existing comments stay visible either way.
                </p>
              </div>
            </div>
          </div>
          <h3 class="title is-5 mt-5 mb-0">Rekognition</h3>
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
import { ref, computed } from "vue";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import toaster from "../mixins/toaster";

useTitle("Admin Settings");

const newSiteName = ref(null);
const newSiteDescription = ref(null);
const newSiteTrackingCode = ref(null);
const newContinueWithGoogleEnabled = ref(null);
const newContinueWithFacebookEnabled = ref(null);
const newRekognitionEnabled = ref(null);
const newCommentingEnabled = ref(null);
const showReloadButton = ref(false);

const ADMIN_SETTINGS_QUERY = gql`
  query AdminSettingsQuery {
    adminSettings {
      id
      siteName
      siteDescription
      siteTrackingCode
      continueWithGoogleEnabled
      continueWithFacebookEnabled
      rekognitionEnabled
      commentingEnabled
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
const rekognitionEnabled = computed({
  get: () => result.value?.adminSettings.rekognitionEnabled,
  set: (value) => {
    newRekognitionEnabled.value = value;
  },
});
const commentingEnabled = computed({
  get: () => result.value?.adminSettings.commentingEnabled,
  set: (value) => {
    newCommentingEnabled.value = value;
  },
});

const {
  mutate: submit,
  onDone,
  onError,
} = useMutation(
  gql`
    mutation (
      $siteName: String!
      $siteDescription: String!
      $siteTrackingCode: String!
      $continueWithGoogleEnabled: Boolean!
      $continueWithFacebookEnabled: Boolean!
      $rekognitionEnabled: Boolean!
      $commentingEnabled: Boolean!
    ) {
      updateAdminSettings(
        siteName: $siteName
        siteDescription: $siteDescription
        siteTrackingCode: $siteTrackingCode
        continueWithGoogleEnabled: $continueWithGoogleEnabled
        continueWithFacebookEnabled: $continueWithFacebookEnabled
        rekognitionEnabled: $rekognitionEnabled
        commentingEnabled: $commentingEnabled
      ) {
        id
        siteName
        siteDescription
        siteTrackingCode
        continueWithGoogleEnabled
        continueWithFacebookEnabled
        rekognitionEnabled
        commentingEnabled
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
      rekognitionEnabled:
        newRekognitionEnabled.value !== null
          ? newRekognitionEnabled.value
          : rekognitionEnabled.value,
      commentingEnabled:
        newCommentingEnabled.value !== null
          ? newCommentingEnabled.value
          : commentingEnabled.value,
    },
  }),
);

onDone(({ data }) => {
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
