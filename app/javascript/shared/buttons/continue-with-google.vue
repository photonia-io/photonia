<template>
  <div ref="mount" class="google-button-center"></div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from "vue";
import {
  computeResponsiveWidth,
  setupResizeObservers,
} from "@/mixins/responsive-button";

const props = defineProps({
  clientId: { type: String, required: true },
  onContinue: { type: Function, required: true },
});

const mount = ref(null);
let lastRenderedWidth = null;
let teardownResize = null;

const renderButton = () => {
  const el = mount.value;
  if (
    !el ||
    !window.google ||
    !window.google.accounts ||
    !window.google.accounts.id
  )
    return;

  const desiredWidth = computeResponsiveWidth(el);

  if (lastRenderedWidth === desiredWidth) return;
  lastRenderedWidth = desiredWidth;

  el.innerHTML = "";

  window.google.accounts.id.renderButton(el, {
    type: "standard",
    shape: "rectangular",
    theme: "outline",
    text: "continue_with",
    size: "large",
    logo_alignment: "center",
    width: desiredWidth,
  });
};

const init = () => {
  if (!window.google || !window.google.accounts || !window.google.accounts.id)
    return;
  window.continueWithGoogle = props.onContinue;
  window.google.accounts.id.initialize({
    client_id: props.clientId,
    callback: window.continueWithGoogle,
    ux_mode: "popup",
  });
  renderButton();
};

onMounted(() => {
  if (window.google && window.google.accounts && window.google.accounts.id) {
    init();
  } else {
    const existing = document.querySelector(
      'script[src="https://accounts.google.com/gsi/client"]',
    );
    if (existing) {
      existing.addEventListener("load", init, { once: true });
    } else {
      const script = document.createElement("script");
      script.src = "https://accounts.google.com/gsi/client";
      script.async = true;
      script.defer = true;
      script.onload = init;
      document.body.appendChild(script);
    }
  }

  teardownResize = setupResizeObservers(mount.value, renderButton, 150);
});

onBeforeUnmount(() => {
  if (teardownResize) {
    teardownResize();
    teardownResize = null;
  }
});
</script>

<style scoped>
.google-button-center {
  display: flex;
  justify-content: center;
}
</style>
