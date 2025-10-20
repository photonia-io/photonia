import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

export const useApplicationStore = defineStore("application", () => {
  const navigationShortcutsEnabled = ref(true);
  const editing = ref(false);
  const managingAlbum = ref(false);
  const selectionMode = ref(localStorage.getItem("selectionMode") === "true");

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

  function startManagingAlbum() {
    managingAlbum.value = true;
  }

  function stopManagingAlbum() {
    managingAlbum.value = false;
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
    exitSelectionMode();
  }

  return {
    navigationShortcutsEnabled,
    enableNavigationShortcuts,
    disableNavigationShortcuts,
    editing,
    startEditing,
    stopEditing,
    managingAlbum,
    startManagingAlbum,
    stopManagingAlbum,
    selectionMode,
    colorScheme,
    setUserColorScheme,
    enterSelectionMode,
    exitSelectionMode,
    toggleSelectionMode,
    showLabelsOnHero,
    signOut,
  };
});
