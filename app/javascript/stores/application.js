import { defineStore } from "pinia";
import { ref, watch } from "vue";

export const useApplicationStore = defineStore("application", () => {
  const navigationShortcutsEnabled = ref(true);
  const selectionMode = ref(localStorage.getItem("selectionMode") === "true");

  function enableNavigationShortcuts() {
    navigationShortcutsEnabled.value = true;
  }

  function disableNavigationShortcuts() {
    navigationShortcutsEnabled.value = false;
  }

  watch(selectionMode, (newValue) => {
    localStorage.setItem("selectionMode", newValue);
  });

  function enterSelectionMode() {
    selectionMode.value = true;
  }

  function exitSelectionMode() {
    selectionMode.value = false;
  }

  function toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
  }

  function signOut() {
    exitSelectionMode();
  }

  return {
    navigationShortcutsEnabled,
    enableNavigationShortcuts,
    disableNavigationShortcuts,
    selectionMode,
    enterSelectionMode,
    exitSelectionMode,
    toggleSelectionMode,
    signOut,
  };
});
