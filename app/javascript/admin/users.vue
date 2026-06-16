<template>
  <div>
    <div class="card">
      <div class="card-content">
        <div v-if="loading" class="has-text-centered">
          <p>Loading users...</p>
        </div>
        <div v-else-if="error" class="notification is-danger">
          <p>Error loading users: {{ error.message }}</p>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-hoverable">
            <thead>
              <tr>
                <th>ID</th>
                <th>Display Name</th>
                <th>Email</th>
                <th>Provider</th>
                <th>Admin</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="user in users"
                :key="user.id"
                @click="viewUser(user.id)"
                style="cursor: pointer"
              >
                <td>{{ user.id }}</td>
                <td>{{ user.displayName || "-" }}</td>
                <td>{{ user.email }}</td>
                <td>
                  <span
                    class="tag"
                    :class="{
                      'is-info': user.signupProvider === 'google',
                      'is-link': user.signupProvider === 'facebook',
                      'is-light': user.signupProvider === 'local',
                    }"
                  >
                    {{ user.signupProvider }}
                  </span>
                </td>
                <td>
                  <span v-if="user.admin" class="tag is-success">Yes</span>
                  <span v-else class="tag">No</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";
import { useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

const router = useRouter();

const USERS_QUERY = gql`
  query UsersQuery {
    users {
      id
      email
      firstName
      lastName
      displayName
      signupProvider
      admin
    }
  }
`;

const { result, loading, error } = useQuery(USERS_QUERY);
const users = computed(() => result.value?.users || []);

const viewUser = (userId) => {
  router.push({ name: "admin-show-user", params: { id: userId } });
};
</script>
