<template>
  <div class="container">
    <div class="columns is-centered mt-5 mb-0">
      <div class="column is-5-tablet is-5-desktop is-5-widescreen">
        <div class="box">
          <h2 class="title is-4">Sign in or sign up</h2>
          <div
            v-if="settings.continue_with_google_enabled"
            id="google-signin"
            class="mb-3"
          >
            <div ref="googleButtonMount" class="google-button-center"></div>
          </div>

          <div
            v-if="settings.continue_with_facebook_enabled"
            id="facebook-signin"
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
import { ref, onMounted, onBeforeUnmount } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";
import { useUserStore } from "../stores/user";
import { useRouter } from "vue-router";
import toaster from "../mixins/toaster";

const settings = ref(window.settings);

const email = ref("");
const password = ref("");
const router = useRouter();

const googleButtonMount = ref(null);
let googleResizeObserver = null;
let lastRenderedWidth = null;
let resizeTimeout = null;
let windowResizeHandler = null;

const renderGoogleButton = () => {
  const mountEl = googleButtonMount.value;
  if (
    !mountEl ||
    !window.google ||
    !window.google.accounts ||
    !window.google.accounts.id
  )
    return;

  const parentEl = mountEl.parentElement;
  const parentWidth = parentEl ? parentEl.clientWidth : 0;

  // If parent is 400px or smaller, fill it exactly; otherwise cap at 400
  const desiredWidth =
    parentWidth <= 400 ? Math.max(120, Math.floor(parentWidth)) : 400;

  // Only re-render if width actually changed
  if (lastRenderedWidth === desiredWidth) return;

  // Update last width before rendering to avoid loops with ResizeObserver
  lastRenderedWidth = desiredWidth;

  // Clear previous render to avoid duplicates
  mountEl.innerHTML = "";

  window.google.accounts.id.renderButton(mountEl, {
    type: "standard",
    shape: "rectangular",
    theme: "outline",
    text: "continue_with",
    size: "large",
    logo_alignment: "center",
    width: desiredWidth,
  });
};

const initGoogleButton = () => {
  if (!window.google || !window.google.accounts || !window.google.accounts.id)
    return;

  window.google.accounts.id.initialize({
    client_id: settings.value.google_client_id,
    callback: continueWithGoogle,
    ux_mode: "popup",
  });

  renderGoogleButton();
};

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
    googleScript.defer = true;
    googleScript.onload = () => {
      // Keep for compatibility if referenced elsewhere
      window.continueWithGoogle = continueWithGoogle;

      initGoogleButton();

      const parentEl = googleButtonMount.value?.parentElement;
      if (parentEl && "ResizeObserver" in window) {
        googleResizeObserver = new ResizeObserver(() => {
          clearTimeout(resizeTimeout);
          resizeTimeout = setTimeout(() => {
            renderGoogleButton();
          }, 150);
        });
        googleResizeObserver.observe(parentEl);
      } else {
        windowResizeHandler = () => {
          clearTimeout(resizeTimeout);
          resizeTimeout = setTimeout(() => {
            renderGoogleButton();
          }, 150);
        };
        window.addEventListener("resize", windowResizeHandler);
      }
    };
    document.body.appendChild(googleScript);
  }

  if (window.settings.continue_with_facebook_enabled) {
    const facebookScript = document.createElement("script");
    facebookScript.src =
      "https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v21.0&appId=" +
      window.settings.facebook_app_id;
    facebookScript.async = true;
    facebookScript.defer = true;
    facebookScript.crossOrigin = "anonymous";
    document.body.appendChild(facebookScript);

    window.continueWithFacebook = continueWithFacebook;
  }
});

onBeforeUnmount(() => {
  if (googleResizeObserver) {
    googleResizeObserver.disconnect();
    googleResizeObserver = null;
  }
  if (windowResizeHandler) {
    window.removeEventListener("resize", windowResizeHandler);
    windowResizeHandler = null;
  }
  if (resizeTimeout) {
    clearTimeout(resizeTimeout);
    resizeTimeout = null;
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
  userStore.uploader = user.uploader;
  router.push({ name: "users-settings" });
};
</script>

<style>
.google-button-center {
  display: flex;
  justify-content: center;
}
</style>
