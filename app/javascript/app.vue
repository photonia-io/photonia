<template>
  <div>
    <Navigation></Navigation>
    <RouterView></RouterView>
    <Footer></Footer>
  </div>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Navigate</p>
        </header>
        <div class="modal-card-body">
          <p>
            You are modifying something. Are you sure you want to navigate away?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="navigateAway">Yes</button>
            <button class="button is-info" @click="closeConfirmationModal">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import Navigation from "./navigation.vue";
import Footer from "./footer.vue";

import { useApplicationStore } from "@/stores/application";
import { ref, watch } from "vue";
import { storeToRefs } from "pinia";
import { useRouter } from "vue-router";

const router = useRouter();

const applicationStore = useApplicationStore();
const { colorScheme } = storeToRefs(applicationStore);

const modalActive = ref(false);
const navigateTo = ref(null);

function setColorScheme(cs) {
  document.documentElement.setAttribute("data-theme", cs);
}

watch(colorScheme, (cs) => {
  setColorScheme(cs);
});

setColorScheme(colorScheme.value);

router.beforeEach((to) => {
  if (applicationStore.editing) {
    navigateTo.value = to;
    modalActive.value = true;
    return false;
  }
});

const closeConfirmationModal = () => {
  modalActive.value = false;
};

const navigateAway = () => {
  applicationStore.editing = false;
  modalActive.value = false;
  router.push(navigateTo.value);
};
</script>
