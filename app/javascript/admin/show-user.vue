<template>
  <div>
    <div class="card">
      <div class="card-content">
        <div v-if="loading" class="has-text-centered">
          <p>Loading user...</p>
        </div>
        <div v-else-if="error" class="notification is-danger">
          <p>Error loading user: {{ error.message }}</p>
        </div>
        <div v-else-if="user">
          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">User ID</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input class="input" type="text" :value="user.id" readonly />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Email</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="email"
                    :value="user.email"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">First Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.firstName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Last Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.lastName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Display Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.displayName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Signup Provider</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <span
                    class="tag is-medium"
                    :class="{
                      'is-info': user.signupProvider === 'google',
                      'is-link': user.signupProvider === 'facebook',
                      'is-light': user.signupProvider === 'local',
                    }"
                  >
                    <span v-if="user.signupProvider === 'google'">
                      <i class="fab fa-google mr-2"></i>
                    </span>
                    <span v-if="user.signupProvider === 'facebook'">
                      <i class="fab fa-facebook mr-2"></i>
                    </span>
                    {{ user.signupProvider }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Admin</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <span v-if="user.admin" class="tag is-success is-medium"
                    >Yes</span
                  >
                  <span v-else class="tag is-medium">No</span>
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Timezone</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.timezone?.name || '-'"
                    readonly
                  />
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
                <div class="control">
                  <button class="button" @click="goBack">
                    <span>Back to Users</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

const route = useRoute();
const router = useRouter();

const USER_QUERY = gql`
  query UserQuery($id: String!) {
    user(id: $id) {
      id
      email
      firstName
      lastName
      displayName
      signupProvider
      admin
      timezone {
        name
      }
    }
  }
`;

const { result, loading, error } = useQuery(USER_QUERY, {
  id: route.params.id,
});

const user = computed(() => result.value?.user);

const goBack = () => {
  router.push({ name: "admin-users" });
};
</script>
