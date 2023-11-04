<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">User Settings</h1>
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
                  <p class="control is-expanded has-icons-left has-icons-right">
                    <input
                      class="input"
                      type="email"
                      placeholder="Email"
                      v-model="email"
                      disabled
                    />
                    <span class="icon is-small is-left">
                      <i class="far fa-envelope"></i>
                    </span>
                    <span class="icon is-small is-right"
                      ><i class="mdi mdi-check"></i
                    ></span>
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
import { ref, watch } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import toaster from "../mixins/toaster";

useTitle("User Settings");

const email = ref("");
const timezone = ref("");

const { result } = useQuery(
  gql`
    query UserSettingsQuery {
      userSettings {
        email
        timezone {
          name
        }
      }
      timezones {
        name
      }
    }
  `
);

watch(result, () => {
  email.value = result.value?.userSettings?.email;
  timezone.value = result.value?.userSettings?.timezone?.name;
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
      timezone: timezone.value,
    },
  })
);

onDone(({ data }) => {
  toaster("Settings saved");
});

onError((error) => {
  toaster("Error saving settings", "is-danger");
});
</script>
