import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

import { useSelectionStore } from "@/stores/selection";

export const useApplicationStore = defineStore("application", () => {
  const navigationShortcutsEnabled = ref(true);
  // we are editing either photo details or album details, details = title or description
  const editing = ref(false);

  const systemColorScheme =
    window.matchMedia &&
    window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  const userColorScheme = ref(localStorage.getItem("userColorScheme"));
  const colorScheme = computed(() =>
    userColorScheme.value ? userColorScheme.value : systemColorScheme,
  );

  const showLabelsOnHero = ref(
    localStorage.getItem("showLabelsOnHero") === "true",
  );

  function enableNavigationShortcuts() {
    navigationShortcutsEnabled.value = true;
  }

  function disableNavigationShortcuts() {
    navigationShortcutsEnabled.value = false;
  }

  function startEditing() {
    editing.value = true;
    disableNavigationShortcuts();
  }

  function stopEditing() {
    editing.value = false;
    enableNavigationShortcuts();
  }

  watch(userColorScheme, (newValue) => {
    localStorage.setItem("userColorScheme", newValue);
  });

  function setUserColorScheme(value) {
    userColorScheme.value = value;
  }

  watch(showLabelsOnHero, (newValue) => {
    localStorage.setItem("showLabelsOnHero", newValue);
  });

  function signOut() {
    const selectionStore = useSelectionStore();
    selectionStore.clearAll();
  }

  // Global navigation confirmation modal state
  const navModalActive = ref(false);
  const navModalMessage = ref("");
  const navNavigateTo = ref(null);
  const navAction = ref(null); // "stopEditing"

  function openNavigationModal(to, message, action) {
    navNavigateTo.value = to;
    navModalMessage.value = message;
    navAction.value = action;
    navModalActive.value = true;
    disableNavigationShortcuts();
  }

  function closeNavigationModal() {
    navModalActive.value = false;
    enableNavigationShortcuts();
  }

  return {
    navigationShortcutsEnabled,
    enableNavigationShortcuts,
    disableNavigationShortcuts,
    editing,
    startEditing,
    stopEditing,
    colorScheme,
    setUserColorScheme,
    showLabelsOnHero,
    signOut,

    // navigation confirmation modal
    navModalActive,
    navModalMessage,
    navNavigateTo,
    navAction,
    openNavigationModal,
    closeNavigationModal,
  };
});
