import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export const useTokenStore = defineStore('token', () => {
  const authorization = ref('')

  function signOut() {
    authorization.value = ''
  }

  const authorizationInStorage = localStorage.getItem('authorization')
  if (authorizationInStorage) {
    // todo console.log('authorization was found in local storage')
    authorization.value = authorizationInStorage
  }

  watch(authorization, (newValue) => {
    // todo console.log('new value for authorization detected', newValue)
    localStorage.setItem('authorization', newValue)
  })

  return { authorization, signOut }
})
