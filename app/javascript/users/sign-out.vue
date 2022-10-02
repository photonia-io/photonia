<template>
  <div class="container">
    Signing out
  </div>
</template>

<script>
import gql from 'graphql-tag'

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
