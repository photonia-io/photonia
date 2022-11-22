import { defineStore } from 'pinia'

export const useTokenStore = defineStore('token', {
  state: () => ({
    authorization: '',
  }),
})
