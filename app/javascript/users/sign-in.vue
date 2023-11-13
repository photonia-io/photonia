<template>
  <div class="container">
    <div class="columns is-centered mt-5 mb-0">
      <div class="column is-5-tablet is-5-desktop is-5-widescreen">
        <form @submit.prevent="submit" class="box">
          <div class="field">
            <label for="" class="label">Email</label>
            <div class="control has-icons-left">
              <input
                v-model="email"
                type="email"
                name="email"
                placeholder="e.g. johnsmith@gmail.com"
                class="input"
                required
              />
              <span class="icon is-small is-left">
                <i class="fa fa-envelope"></i>
              </span>
            </div>
          </div>
          <div class="field">
            <label for="" class="label">Password</label>
            <div class="control has-icons-left">
              <input
                v-model="password"
                type="password"
                name="password"
                placeholder="********"
                class="input"
                required
              />
              <span class="icon is-small is-left">
                <i class="fa fa-lock"></i>
              </span>
            </div>
          </div>
          <div class="field">
            <button class="button">Sign In</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";
import { useUserStore } from "../stores/user";
import { useRouter } from "vue-router";
import toaster from "../mixins/toaster";

const email = ref("");
const password = ref("");
const router = useRouter();

const {
  mutate: submit,
  onDone,
  onError,
} = useMutation(
  gql`
    mutation ($email: String!, $password: String!) {
      signIn(email: $email, password: $password) {
        email
        admin
      }
    }
  `,
  () => ({
    variables: {
      email: email.value,
      password: password.value,
    },
  })
);

onDone(({ data }) => {
  const userStore = useUserStore();
  userStore.signedIn = true;
  userStore.email = data.signIn.email;
  userStore.admin = data.signIn.admin;
  router.push({ name: "users-settings" });
});

onError((error) => {
  const userStore = useUserStore();
  userStore.signOut();
  toaster("There was an error signing you in. Please try again.", "is-danger");
});
</script>

<style></style>
