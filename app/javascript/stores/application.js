import { defineStore } from "pinia";
import { ref, watch } from "vue";

export const useApplicationStore = defineStore("application", () => {
  const navigationShortcutsEnabled = ref(true);
  const selectionMode = ref(localStorage.getItem("selectionMode") === "true");
  const showLabelsOnHero = ref(
    localStorage.getItem("showLabelsOnHero") === "true"
  );

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

  watch(showLabelsOnHero, (newValue) => {
    console.log("showLabelsOnHero", newValue);
    localStorage.setItem("showLabelsOnHero", newValue);
  });

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
    showLabelsOnHero,
    signOut,
  };
});
