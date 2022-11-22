<template>
  <div class="container">
    Signing out...
  </div>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useMutation } from '@vue/apollo-composable'
  import { useUserStore } from '../stores/user'
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
    router.push({ name: 'root' })
  })

  onError((error) => {
    console.log(error)
  })

  mutate()
</script>
