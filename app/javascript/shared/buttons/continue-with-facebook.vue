<template>
  <div ref="mount" class="facebook-button-center"></div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from "vue";
import {
  computeResponsiveWidth,
  setupResizeObservers,
} from "@/mixins/responsive-button";

const props = defineProps({
  appId: { type: String, required: true },
  onContinue: { type: Function, required: true },
});

const mount = ref(null);
let lastRenderedWidth = null;
let teardownResize = null;

const renderButton = () => {
  const el = mount.value;
  if (!el || !window.FB) return;

  const desiredWidth = computeResponsiveWidth(el);
  if (desiredWidth <= 0) return;

  // Only re-render if width actually changed
  if (lastRenderedWidth === desiredWidth) return;
  lastRenderedWidth = desiredWidth;

  // Clear previous render to avoid duplicates
  el.innerHTML = "";

  // Build fresh XFBML button and parse
  const btn = document.createElement("div");
  btn.className = "fb-login-button";
  btn.setAttribute("data-width", String(desiredWidth));
  btn.setAttribute("data-size", "large");
  btn.setAttribute("data-button-type", "continue_with");
  btn.setAttribute("data-layout", "default");
  btn.setAttribute("data-onlogin", "continueWithFacebook");
  btn.setAttribute("data-auto-logout-link", "false");
  btn.setAttribute("data-use-continue-as", "false");
  btn.setAttribute("data-scope", "public_profile,email");

  el.appendChild(btn);
  window.FB.XFBML.parse(el);
};

let globalCallbackName = null;

const setGlobalOnLogin = () => {
  globalCallbackName = "continueWithFacebook";
  // Ensure the XFBML onlogin handler calls the provided callback with a response
  window.continueWithFacebook = () => {
    try {
      window.FB.getLoginStatus((response) => {
        // response has { status, authResponse: { accessToken, ... }, ... }
        props.onContinue(response);
      });
    } catch (e) {
      // Fallback: call without response to avoid breaking caller
      props.onContinue({});
    }
  };
};

const initAndRender = () => {
  setGlobalOnLogin();
  renderButton();
  teardownResize = setupResizeObservers(mount.value, renderButton, 150);
};

onMounted(() => {
  if (window.FB) {
    // SDK already present (and likely initialized elsewhere)
    initAndRender();
  } else {
    // Initialize SDK ourselves with xfbml disabled; we'll parse on demand
    window.fbAsyncInit = function () {
      window.FB.init({
        appId: props.appId,
        cookie: true,
        xfbml: false,
        version: "v24.0",
      });
      initAndRender();
    };

    const existing = document.querySelector(
      'script[src="https://connect.facebook.net/en_US/sdk.js"]',
    );
    if (!existing) {
      const script = document.createElement("script");
      script.src = "https://connect.facebook.net/en_US/sdk.js";
      script.async = true;
      script.defer = true;
      script.crossOrigin = "anonymous";
      document.body.appendChild(script);
    } else {
      // If script exists but not loaded yet, rely on fbAsyncInit. If it has already loaded,
      // FB will be present and onMounted's first branch would have handled it.
    }
  }
});

onBeforeUnmount(() => {
  if (teardownResize) {
    teardownResize();
    teardownResize = null;
  }
  if (globalCallbackName && window[globalCallbackName]) {
    delete window[globalCallbackName];
    globalCallbackName = null;
  }
});
</script>

<style scoped>
.facebook-button-center {
  display: flex;
  justify-content: center;
}
</style>
