import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useApplicationStore = defineStore('application', () => {
  const photoListChanged = ref(false)
  const navigationShortcutsEnabled = ref(true)

  function enableNavigationShortcuts() {
    navigationShortcutsEnabled.value = true
  }

  function disableNavigationShortcuts() {
    navigationShortcutsEnabled.value = false
  }

  return {
    navigationShortcutsEnabled,
    photoListChanged,
    enableNavigationShortcuts,
    disableNavigationShortcuts
  }
})
