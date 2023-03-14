import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const signedIn = ref(false)
  const email = ref('')

  function signOut() {
    signedIn.value = false
    email.value = ''
  }

  return { signedIn, email, signOut }
})