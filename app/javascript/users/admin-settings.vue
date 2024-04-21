<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Admin Settings</h1>
      <hr class="mt-2 mb-4" />
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
  </section>
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
const newSiteTrackingCode = ref("");
const showReloadButton = ref(false);

const ADMIN_SETTINGS_QUERY = gql`
  query AdminSettingsQuery {
    adminSettings {
      siteName
      siteDescription
      siteTrackingCode
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
    ) {
      updateAdminSettings(
        siteName: $siteName
        siteDescription: $siteDescription
        siteTrackingCode: $siteTrackingCode
      ) {
        siteName
        siteDescription
        siteTrackingCode
      }
    }
  `,
  () => ({
    variables: {
      siteName: newSiteName.value || siteName.value,
      siteDescription: newSiteDescription.value || siteDescription.value,
      siteTrackingCode: newSiteTrackingCode.value,
    },
    update: (cache, { data }) => {
      cache.writeQuery({
        query: ADMIN_SETTINGS_QUERY,
        data: {
          adminSettings: data.updateAdminSettings,
        },
      });
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
