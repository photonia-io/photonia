<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">User Settings</h1>
          </div>
        </div>
        <div class="level-right">
          <div class="level-item">
            <router-link
              :to="{ name: 'users-admin-settings' }"
              v-if="userStore.admin"
              class="button is-small is-link"
            >
              Admin Settings
            </router-link>
          </div>
        </div>
      </div>
      <hr class="mt-2 mb-4" />
      <div class="card">
        <div class="card-content">
          <form @submit.prevent="submit">
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">Email</label>
              </div>
              <div class="field-body">
                <div class="field">
                  <p class="control is-expanded has-icons-left">
                    <input
                      class="input"
                      type="email"
                      name="email"
                      placeholder="Email"
                      v-model="email"
                      disabled
                    />
                    <span class="icon is-small is-left">
                      <i class="far fa-envelope"></i>
                    </span>
                  </p>
                </div>
              </div>
            </div>
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">First Name</label>
              </div>
              <div class="field-body">
                <div class="field">
                  <p class="control">
                    <input
                      class="input"
                      type="text"
                      name="firstName"
                      placeholder="John"
                      v-model="firstName"
                    />
                  </p>
                </div>
              </div>
            </div>
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">Last Name</label>
              </div>
              <div class="field-body">
                <div class="field">
                  <p class="control">
                    <input
                      class="input"
                      type="text"
                      name="lastName"
                      placeholder="Smith"
                      v-model="lastName"
                    />
                  </p>
                </div>
              </div>
            </div>
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">Display Name</label>
              </div>
              <div class="field-body">
                <div class="field">
                  <p class="control">
                    <input
                      class="input"
                      type="text"
                      name="displayName"
                      placeholder="John Smith"
                      v-model="displayName"
                    />
                  </p>
                </div>
              </div>
            </div>
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">Timezone</label>
              </div>
              <div class="field-body">
                <div class="field is-expanded">
                  <div class="control">
                    <div class="select is-fullwidth">
                      <select v-if="result" v-model="timezone">
                        <option
                          v-for="tz in result.timezones"
                          :value="tz.name"
                          :key="tz.name"
                        >
                          {{ tz.name }}
                        </option>
                      </select>
                    </div>
                  </div>
                  <p class="help">
                    Select the timezone your camera's time is set to. This will
                    apply to photos uploaded from this point forward.
                  </p>
                </div>
              </div>
            </div>
            <div class="field is-horizontal">
              <div class="field-label is-normal">
                <label class="label">Default License</label>
              </div>
              <div class="field-body">
                <div class="field is-expanded">
                  <div class="control">
                    <div class="select is-fullwidth">
                      <select v-model="defaultLicense">
                        <option value="">None</option>
                        <option value="CC BY 4.0">CC BY 4.0 - Attribution</option>
                        <option value="CC BY-SA 4.0">CC BY-SA 4.0 - Attribution-ShareAlike</option>
                        <option value="CC BY-ND 4.0">CC BY-ND 4.0 - Attribution-NoDerivatives</option>
                        <option value="CC BY-NC 4.0">CC BY-NC 4.0 - Attribution-NonCommercial</option>
                        <option value="CC BY-NC-SA 4.0">CC BY-NC-SA 4.0 - Attribution-NonCommercial-ShareAlike</option>
                        <option value="CC BY-NC-ND 4.0">CC BY-NC-ND 4.0 - Attribution-NonCommercial-NoDerivatives</option>
                        <option value="CC0 1.0">CC0 1.0 - Public Domain Dedication</option>
                        <option value="Public Domain">Public Domain</option>
                      </select>
                    </div>
                  </div>
                  <p class="help">
                    Select the default license for photos you upload. This will
                    be automatically applied to new uploads.
                    <a @click.prevent="showLicenseInfoModal" class="has-text-link" style="cursor: pointer;">
                      Learn more about licenses
                    </a>
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
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  </section>
  <LicenseInfoModal v-model="licenseInfoModalActive" />
</template>

<script setup>
import { ref, computed } from "vue";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "@/stores/user";
import toaster from "../mixins/toaster";
import LicenseInfoModal from "../shared/license-info-modal.vue";

const CURRENT_USER_QUERY = gql`
  query CurrentUserQuery {
    currentUser {
      id
      email
      firstName
      lastName
      displayName
      defaultLicense
      timezone {
        name
      }
    }
    timezones {
      name
    }
  }
`;

useTitle("User Settings");

const userStore = useUserStore();

const newTimezone = ref(null);
const newFirstName = ref(null);
const newLastName = ref(null);
const newDisplayName = ref(null);
const newDefaultLicense = ref(null);
const licenseInfoModalActive = ref(false);

const { result } = useQuery(CURRENT_USER_QUERY);

const showLicenseInfoModal = () => {
  licenseInfoModalActive.value = true;
};

const email = computed(() => result.value?.currentUser.email);
const firstName = computed({
  get: () => result.value?.currentUser.firstName,
  set: (value) => (newFirstName.value = value),
});
const lastName = computed({
  get: () => result.value?.currentUser.lastName,
  set: (value) => (newLastName.value = value),
});
const displayName = computed({
  get: () => result.value?.currentUser.displayName,
  set: (value) => (newDisplayName.value = value),
});
const timezone = computed({
  get: () => result.value?.currentUser.timezone.name,
  set: (value) => (newTimezone.value = value),
});
const defaultLicense = computed({
  get: () => result.value?.currentUser.defaultLicense,
  set: (value) => (newDefaultLicense.value = value),
});

const {
  mutate: submit,
  onDone,
  onError,
} = useMutation(
  gql`
    mutation (
      $email: String!
      $firstName: String!
      $lastName: String!
      $displayName: String!
      $timezone: String!
      $defaultLicense: String
    ) {
      updateUserSettings(
        email: $email
        firstName: $firstName
        lastName: $lastName
        displayName: $displayName
        timezone: $timezone
        defaultLicense: $defaultLicense
      ) {
        id
        email
        firstName
        lastName
        displayName
        defaultLicense
        timezone {
          name
        }
      }
    }
  `,
  () => ({
    variables: {
      email: email.value,
      firstName: newFirstName.value || firstName.value,
      lastName: newLastName.value || lastName.value,
      displayName: newDisplayName.value || displayName.value,
      timezone: newTimezone.value || timezone.value,
      defaultLicense: newDefaultLicense.value !== null ? newDefaultLicense.value : defaultLicense.value,
    },
  }),
);

onDone(({ data }) => {
  toaster("Settings saved");
});

onError((error) => {
  toaster("Error saving settings", "is-danger");
});
</script>
