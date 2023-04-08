<template>
  <div class="container">
    <p class="mt-5 mb-0">Signing out...</p>
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useMutation } from '@vue/apollo-composable'
  import { useUserStore } from '../stores/user'
  import { useTokenStore } from '../stores/token'
  import { useRouter } from 'vue-router'

  const router = useRouter()

  const { mutate, onDone, onError } = useMutation(
    gql`
      mutation {
        signOut { email }
      }
    `
  )

  onDone(({ data }) => {
    const userStore = useUserStore()
    userStore.signOut()
    const tokenStore = useTokenStore()
    tokenStore.signOut()
    router.push({ name: 'root' })
  })

  onError((error) => {
    // todo console.log(error)
  })

  mutate()
</script>
