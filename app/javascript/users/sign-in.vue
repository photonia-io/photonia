<template>
  <div class="container">
    <div class="columns is-centered mt-5 mb-0">
      <div class="column is-5-tablet is-5-desktop is-5-widescreen">
        <div class="box">
          <h2 class="title is-4">Sign in or sign up</h2>
          <div v-if="settings.continue_with_google_enabled">
            <div
              id="g_id_onload"
              data-client_id="1001813754179-e5qgubr1k4787qblpaklhoilih0mgcri.apps.googleusercontent.com"
              data-context="signin"
              data-ux_mode="popup"
              data-callback="continueWithGoogle"
              data-auto_prompt="false"
            ></div>

            <div
              class="g_id_signin"
              data-type="standard"
              data-shape="rectangular"
              data-theme="outline"
              data-text="continue_with"
              data-size="large"
              data-logo_alignment="left"
            ></div>
          </div>

          <div
            v-if="settings.continue_with_facebook_enabled"
            class="fb-login-button"
            data-width=""
            data-size="large"
            data-button-type=""
            data-layout=""
            data-onlogin="continueWithFacebook"
            data-auto-logout-link="false"
            data-use-continue-as="false"
            data-scope="public_profile,email"
          ></div>
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
import { ref, onMounted } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";
import { useUserStore } from "../stores/user";
import { useRouter } from "vue-router";
import toaster from "../mixins/toaster";

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

onSignInError((error) => {
  const userStore = useUserStore();
  userStore.signOut();
  toaster("There was an error signing you in. Please try again.", "is-danger");
});

onMounted(() => {
  if (window.settings.continue_with_google_enabled) {
    const googleScript = document.createElement("script");
    googleScript.src = "https://accounts.google.com/gsi/client";
    googleScript.async = true;
    document.body.appendChild(googleScript);

    window.continueWithGoogle = continueWithGoogle;
  }

  if (window.settings.continue_with_facebook_enabled) {
    const facebookScript = document.createElement("script");
    facebookScript.src =
      "https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v21.0&appId=560245602871568";
    facebookScript.async = true;
    facebookScript.defer = true;
    facebookScript.crossOrigin = "anonymous";
    document.body.appendChild(facebookScript);

    window.continueWithFacebook = continueWithFacebook;
  }
});

const continueWithGoogle = (response) => {
  continueWithGoogleMutation({
    credential: response.credential,
    clientId: response.client_id,
  });
};

const continueWithFacebook = (response) => {
  continueWithFacebookMutation({
    accessToken: response.authResponse.accessToken,
    signedRequest: response.authResponse.signedRequest,
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
    }
  }
`);

onContiueWithGoogleDone(({ data }) => {
  signInAndRedirect(data.continueWithGoogle);
});

onContiueWithGoogleError((error) => {
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
    }
  }
`);

onContiueWithFacebookDone(({ data }) => {
  signInAndRedirect(data.continueWithFacebook);
});

onContiueWithFacebookError((error) => {
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
  router.push({ name: "users-settings" });
};
</script>

<style></style>
