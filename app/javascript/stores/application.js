import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useApplicationStore = defineStore('application', () => {
  const navigationShortcutsEnabled = ref(true)

  function enableNavigationShortcuts() {
    navigationShortcutsEnabled.value = true
  }

  function disableNavigationShortcuts() {
    navigationShortcutsEnabled.value = false
  }

  return { navigationShortcutsEnabled, enableNavigationShortcuts, disableNavigationShortcuts }
})
