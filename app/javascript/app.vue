<template>
  <div :class="{ 'has-selection-bar': selectionStore.count > 0 }">
    <Navigation></Navigation>
    <RouterView></RouterView>
    <Footer></Footer>
  </div>
  <SelectionBar />
  <teleport to="#modal-root">
    <div
      :class="['modal', applicationStore.navModalActive ? 'is-active' : null]"
    >
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Navigate</p>
        </header>
        <div class="modal-card-body">
          <p>{{ applicationStore.navModalMessage }}</p>
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
import SelectionBar from "@/shared/selection-bar.vue";

import { useApplicationStore } from "@/stores/application";
import { useSelectionStore } from "@/stores/selection";
import { onMounted, onUnmounted, watch } from "vue";
import { storeToRefs } from "pinia";
import { useRouter } from "vue-router";

const router = useRouter();

const applicationStore = useApplicationStore();
const { colorScheme } = storeToRefs(applicationStore);
const selectionStore = useSelectionStore();

function setColorScheme(cs) {
  document.documentElement.setAttribute("data-theme", cs);
}

watch(colorScheme, (cs) => {
  setColorScheme(cs);
});

setColorScheme(colorScheme.value);

const closeConfirmationModal = () => {
  applicationStore.closeNavigationModal();
};

const navigateAway = () => {
  if (applicationStore.navAction === "stopEditing") {
    // we arrived here while editing a photo or album's details
    applicationStore.stopEditing();
  }
  const target = applicationStore.navNavigateTo;
  applicationStore.closeNavigationModal();
  if (target) {
    router.push(target);
  }
};

// Escape clears the selection, but only when nothing else (a modal, inline
// editing) has already claimed it via disableNavigationShortcuts.
const handleGlobalKeydown = (event) => {
  if (event.key !== "Escape") return;
  if (!applicationStore.navigationShortcutsEnabled) return;
  if (selectionStore.count > 0) selectionStore.clear();
};

onMounted(() => document.addEventListener("keydown", handleGlobalKeydown));
onUnmounted(() => document.removeEventListener("keydown", handleGlobalKeydown));
</script>
