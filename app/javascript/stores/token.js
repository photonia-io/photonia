import { defineStore } from 'pinia'

export const useTokenStore = defineStore('token', {
  state: () => ({
    accessToken: '',
    tokenType: 'Bearer',
    client: '',
    expiry: '',
    uid: '',
  }),
})
