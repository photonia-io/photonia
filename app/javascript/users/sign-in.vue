<template>
  <div class="container">
    <div class="columns is-centered">
      <div class="column is-5-tablet is-5-desktop is-5-widescreen">
        <form
          @submit.prevent="submit"
          class="box"
        >
          <div class="field">
            <label for="" class="label">Email</label>
            <div class="control has-icons-left">
              <input
                v-model="email"
                type="email"
                placeholder="e.g. johnsmith@gmail.com"
                class="input"
                required
              >
              <span class="icon is-small is-left">
                <i class="fa fa-envelope"></i>
              </span>
            </div>
          </div>
          <div class="field">
            <label for="" class="label">Password</label>
            <div class="control has-icons-left">
              <input
                v-model="password"
                type="password"
                placeholder="********"
                class="input"
                required
              >
              <span class="icon is-small is-left">
                <i class="fa fa-lock"></i>
              </span>
            </div>
          </div>
          <div class="field">
            <button class="button">
              Sign In
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import gql from 'graphql-tag'
import { useUserStore } from '../stores/user'

export default {
  setup() {
    return {
      email: '',
      password: '',
    }
  },
  methods: {
    submit() {
      this.$apollo.mutate({
        mutation: gql`
          mutation($email: String!, $password: String!) {
            userLogin(email: $email, password: $password) {
              authenticatable {
                email
              }
            }
          }
        `,
        variables: {
          email: this.email,
          password: this.password
        }
      }).then(({ data }) => {
        const userStore = useUserStore()
        userStore.signedIn = true
        userStore.email = data.userLogin.authenticatable.email
      }).catch((error) => {
        console.log(error)
      })
    }
  }
}
</script>

<style>

</style>
