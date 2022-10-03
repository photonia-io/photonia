import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    signedIn: false,
    email: '',
  })
})
