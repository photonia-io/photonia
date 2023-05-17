import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useApplicationStore = defineStore('application', () => {
  const navigationShortcutsEnabled = ref(true)
  const selectionMode = ref(false)

  function enableNavigationShortcuts() {
    navigationShortcutsEnabled.value = true
  }

  function disableNavigationShortcuts() {
    navigationShortcutsEnabled.value = false
  }

  function enterSelectionMode() {
    selectionMode.value = true
  }

  function exitSelectionMode() {
    selectionMode.value = false
  }

  function toggleSelectionMode() {
    selectionMode.value = !selectionMode.value
  }

  return {
    navigationShortcutsEnabled,
    enableNavigationShortcuts,
    disableNavigationShortcuts,
    selectionMode,
    enterSelectionMode,
    exitSelectionMode,
    toggleSelectionMode
  }
})
