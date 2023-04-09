<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">User Settings</h1>
      <hr class="mt-2 mb-4">
      <p v-if="result">{{ result.userSettings.email }}</p>
    </div>
  </section>
</template>

<script setup>
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  useTitle('User Settings')

  const { result } = useQuery(
    gql`
      query UserSettingsQuery {
        userSettings {
          email
        }
      }
    `
  )
</script>
