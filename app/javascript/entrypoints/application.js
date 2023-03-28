import '@/styles/application.scss'

import { createApp, provide, h, watch } from 'vue'
import App from '../app.vue'

import { createRouter, createWebHistory } from 'vue-router'

import { createPinia } from 'pinia'
const pinia = createPinia()

import { pageTitle } from 'vue-page-title'

import { ApolloClient, createHttpLink, ApolloLink, InMemoryCache } from '@apollo/client/core'
import { setContext } from "@apollo/client/link/context"
import { DefaultApolloClient, provideApolloClient, useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'

import { useTokenStore } from '../stores/token'
import { useUserStore } from '../stores/user'

document.addEventListener('DOMContentLoaded', () => {
  const userStore = useUserStore(pinia)

  const redirectIfNotSignedIn = (to, from) => {
    if (!userStore.signedIn) {
      return { name: 'users-sign-in' }
    }
  }

  const cj = window.configuration_json
  const cjda = cj.data.attributes

  const routes = [
    { path: cjda.root_path, name: 'root', component: () => import('../homepage/index.vue') },
    { path: cjda.photos_path, name: 'photos-index', component: () => import('../photos/index.vue') },
    { path: cjda.photos_path + '/:id', name: 'photos-show', component: () => import('../photos/show.vue') },
    { path: cjda.albums_path, name: 'albums-index', component: () => import('../albums/index.vue') },
    { path: cjda.albums_path + '/:id', name: 'albums-show', component: () => import('../albums/show.vue') },
    { path: cjda.tags_path, name: 'tags-index', component: () => import('../tags/index.vue') },
    { path: cjda.tags_path + '/:id', name: 'tags-show', component: () => import('../tags/show.vue') },
    { path: cjda.users_sign_in_path, name: 'users-sign-in', component: () => import('../users/sign-in.vue') },
    { path: cjda.users_sign_out_path, name: 'users-sign-out', component: () => import('../users/sign-out.vue') },
    { 
      path: cjda.users_settings_path,
      name: 'users-settings',
      component: () => import('../users/settings.vue'),
      beforeEnter: redirectIfNotSignedIn
    },
    {
      path: cjda.photos_path + '/upload',
      name: 'photos-upload',
      component: () => import('../photos/upload.vue'),
      beforeEnter: redirectIfNotSignedIn
    }
  ]

  const router = createRouter({
    history: createWebHistory(),
    routes,
  })

  const tokenStore = useTokenStore(pinia)

  const httpLink = createHttpLink({ uri: cjda.graphql_url })
  const authLink = setContext((_, { headers }) => {
    return {
      headers: {
        ...headers,
        authorization: tokenStore.authorization,
      },
    }
  })

  const afterwareLink = new ApolloLink((operation, forward) => {
    return forward(operation).map((response) => {
      const context = operation.getContext();
      const headers = context.response.headers
      const authorization = headers.get('Authorization')
      if (authorization) {
        tokenStore.$patch({ authorization })
      }
      return response
    })
  })

  const apolloClient = new ApolloClient({
    link: authLink.concat(afterwareLink.concat(httpLink)),
    cache: new InMemoryCache(),
    connectToDevTools: true,
  })

  // if a token was found in local storage, fetch the user

  if (tokenStore.authorization) {
    // console.log('authorization exists', tokenStore.authorization)
    // we will suppose that the token is valid
    userStore.signedIn = true
    provideApolloClient(apolloClient)
    const { result, loading, error } = useQuery(
      gql`
        query UserSettingsQuery {
          userSettings {
            email
          }
        }
      `
    )
  
    watch(result, value => {
      userStore.email = value.userSettings.email
    })
  }

  // go for Vue!

  const app = createApp({
    setup() {
      provide(DefaultApolloClient, apolloClient)
    },
    render: () => h(App),
  })

  app.config.globalProperties.gql_queries = window.gql_queries
  app.config.globalProperties.gql_cached_query = window.gql_cached_query
  app.config.globalProperties.gql_cached_result = window.gql_cached_result

  app.use(router)
  app.use(pinia)

  app.use(
    pageTitle({
      suffix: 'Photonia',
      separator: ' - ',
      mixin: true,
    })
  )

  app.mount('#app')
})
