<template>
  <div class="container">
    <div class="columns is-centered mt-5 mb-0">
      <div class="column is-5-tablet is-5-desktop is-5-widescreen">
        <div class="box">
          <h2 class="title is-4">Sign in or sign up</h2>
          <div>
            <ContinueWithGoogle
              v-if="settings.continue_with_google_enabled"
              class="mb-3"
              :client-id="settings.google_client_id"
              :on-continue="continueWithGoogle"
            />

            <ContinueWithFacebook
              v-if="settings.continue_with_facebook_enabled"
              :app-id="settings.facebook_app_id"
              :on-continue="continueWithFacebook"
            />
          </div>
        </div>

        <form @submit.prevent="submit" class="box">
          <h2 class="title is-4">Sign in with email and password</h2>
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

import ContinueWithGoogle from "@/shared/buttons/continue-with-google.vue";
import ContinueWithFacebook from "@/shared/buttons/continue-with-facebook.vue";

const settings = ref(window.settings);

const email = ref("");
const password = ref("");
const router = useRouter();

const {
  mutate: submit,
  onDone: onSignInDone,
  onError: onSignInError,
} = useMutation(
  gql`
    mutation ($email: String!, $password: String!) {
      signIn(email: $email, password: $password) {
        email
        admin
        uploader
      }
    }
  `,
  () => ({
    variables: {
      email: email.value,
      password: password.value,
    },
  }),
);

onSignInDone(({ data }) => {
  signInAndRedirect(data.signIn);
});

onSignInError((_error) => {
  const userStore = useUserStore();
  userStore.signOut();
  toaster("There was an error signing you in. Please try again.", "is-danger");
});

// Google callback from component
const continueWithGoogle = (response) => {
  continueWithGoogleMutation({
    credential: response.credential,
    clientId: response.client_id,
  });
};

// Facebook callback from component
const continueWithFacebook = (response) => {
  const accessToken = response?.authResponse?.accessToken;
  const signedRequest = response?.authResponse?.signedRequest;

  if (!accessToken || !signedRequest) {
    toaster(
      "Facebook login was not successful. Please try again.",
      "is-danger",
    );
    return;
  }

  continueWithFacebookMutation({
    accessToken,
    signedRequest,
  });
};

const {
  mutate: continueWithGoogleMutation,
  onDone: onContiueWithGoogleDone,
  onError: onContiueWithGoogleError,
} = useMutation(gql`
  mutation ($credential: String!, $clientId: String!) {
    continueWithGoogle(credential: $credential, clientId: $clientId) {
      email
      admin
      uploader
    }
  }
`);

onContiueWithGoogleDone(({ data }) => {
  signInAndRedirect(data.continueWithGoogle);
});

onContiueWithGoogleError((_error) => {
  toaster(
    "There was an error signing you in with Google. Please try again.",
    "is-danger",
  );
});

const {
  mutate: continueWithFacebookMutation,
  onDone: onContiueWithFacebookDone,
  onError: onContiueWithFacebookError,
} = useMutation(gql`
  mutation ($accessToken: String!, $signedRequest: String!) {
    continueWithFacebook(
      accessToken: $accessToken
      signedRequest: $signedRequest
    ) {
      email
      admin
      uploader
    }
  }
`);

onContiueWithFacebookDone(({ data }) => {
  signInAndRedirect(data.continueWithFacebook);
});

onContiueWithFacebookError((_error) => {
  toaster(
    "There was an error signing you in with Facebook. Please try again.",
    "is-danger",
  );
});

const signInAndRedirect = (user) => {
  const userStore = useUserStore();
  userStore.signedIn = true;
  userStore.email = user.email;
  userStore.admin = user.admin;
  userStore.uploader = user.uploader;
  router.push({ name: "users-settings" });
};
</script>

<style></style>
