import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'

import VueRouter from 'vue-router'
Vue.use(VueRouter)

import VueApollo from 'vue-apollo'
Vue.use(VueApollo)

import { createPinia, PiniaVuePlugin } from 'pinia'
Vue.use(PiniaVuePlugin)
const pinia = createPinia()

import VueMoment from 'vue-moment'
Vue.use(VueMoment)

import pageTitle from '../mixins/page-title'
Vue.mixin(pageTitle)

import { ApolloClient, createHttpLink, ApolloLink, InMemoryCache } from '@apollo/client/core'
import { setContext } from "@apollo/client/link/context"
import { createApolloProvider } from '@vue/apollo-option'

import { useTokenStore } from '../stores/token'

Vue.prototype.gql_queries = window.gql_queries
Vue.prototype.gql_cached_query = window.gql_cached_query
Vue.prototype.gql_cached_result = window.gql_cached_result

document.addEventListener('DOMContentLoaded', () => {
  // routes and router start

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
  ]

  const router = new VueRouter({
    mode: 'history',
    routes
  })

  // Apollo

  const tokenStore = useTokenStore(pinia)

  const httpLink = createHttpLink({ uri: cjda.graphql_url })
  const authLink = setContext((_, { headers }) => {
    const csrfToken = document.
      querySelector('meta[name="csrf-token"]').
      attributes.content.value;

    // get the authentication token from local storage if it exists
    // const authToken = localStorage.getItem(AUTH_TOKEN_KEY);

    console.log(tokenStore.accessToken)

    return {
      headers: {
        ...headers,
        'X-CSRF-Token': csrfToken,
        'access-token': tokenStore.accessToken,
        'client': tokenStore.client,
        'uid': tokenStore.uid,
        'token-type': tokenStore.tokenType,
        // authorization: authToken ? `Bearer ${authToken}` : '',
      },
    };
  });
  const afterwareLink = new ApolloLink((operation, forward) => {
    return forward(operation).map((response) => {
      const context = operation.getContext();
      const headers = context.response.headers
      console.log('access-token', headers.get('access-token'))
      tokenStore.$patch({
        accessToken: headers.get('access-token'),
        client: headers.get('client'),
        expiry: headers.get('expiry'),
        tokenType: headers.get('token-type'),
        uid: headers.get('uid')
      })
      return response
    })
  })

  const apolloClient = new ApolloClient({
    link: authLink.concat(afterwareLink.concat(httpLink)),
    cache: new InMemoryCache(),
    // connectToDevTools: true,
  })

  const apolloProvider = createApolloProvider({
    defaultClient: apolloClient,
  })

  // go for Vue!

  const app = new Vue({
    el: '#app',
    apolloProvider,
    router,
    pinia,
    render: h => h(App)
  })
})
