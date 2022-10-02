import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    signedIn: false,
    email: '',
  }),
  getters: {
    isSignedIn() {
      return this.signedIn
    }
  },
})
