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
</template>

<script setup>
import { ref, computed } from "vue";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "@/stores/user";
import toaster from "../mixins/toaster";

const USER_SETTINGS_QUERY = gql`
  query UserSettingsQuery {
    userSettings {
      email
      firstName
      lastName
      displayName
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

const { result } = useQuery(USER_SETTINGS_QUERY);

const email = computed(() => result.value?.userSettings.email);
const firstName = computed({
  get: () => result.value?.userSettings.firstName,
  set: (value) => (newFirstName.value = value),
});
const lastName = computed({
  get: () => result.value?.userSettings.lastName,
  set: (value) => (newLastName.value = value),
});
const displayName = computed({
  get: () => result.value?.userSettings.displayName,
  set: (value) => (newDisplayName.value = value),
});
const timezone = computed({
  get: () => result.value?.userSettings.timezone.name,
  set: (value) => (newTimezone.value = value),
});

const {
  mutate: submit,
  onDone,
  onError,
} = useMutation(
  gql`
    mutation ($email: String!, $timezone: String!) {
      updateUserSettings(email: $email, timezone: $timezone) {
        email
        timezone {
          name
        }
      }
    }
  `,
  () => ({
    variables: {
      email: email.value,
      timezone: newTimezone.value || timezone.value,
    },
    update: (cache, { data }) => {
      cache.writeQuery({
        query: USER_SETTINGS_QUERY,
        data: {
          userSettings: data.updateUserSettings,
        },
      });
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
