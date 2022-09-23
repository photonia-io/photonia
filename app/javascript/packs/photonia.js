import Vue from 'vue/dist/vue.esm'
import AppNavigation from '../navigation.vue'
import AppFooter from '../footer.vue'

import VueRouter from 'vue-router'
Vue.use(VueRouter)

import VueApollo from 'vue-apollo'
Vue.use(VueApollo)

import VueMoment from 'vue-moment'
Vue.use(VueMoment)

import pageTitle from '../mixins/page-title'
Vue.mixin(pageTitle)

import { ApolloClient, createHttpLink, InMemoryCache } from '@apollo/client/core'
import { setContext } from "@apollo/client/link/context"
import { createApolloProvider } from '@vue/apollo-option'

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
  ]

  const router = new VueRouter({
    mode: 'history',
    routes
  })

  // Apollo

  const httpLink = createHttpLink({ uri: cjda.graphql_url })
  const authLink = setContext((_, { headers }) => {
    const csrfToken = document.
      querySelector('meta[name="csrf-token"]').
      attributes.content.value;

    // get the authentication token from local storage if it exists
    // const authToken = localStorage.getItem(AUTH_TOKEN_KEY);

    return {
      headers: {
        ...headers,
        'X-CSRF-Token': csrfToken,
        // authorization: authToken ? `Bearer ${authToken}` : '',
      },
    };
  });

  const apolloClient = new ApolloClient({
    link: authLink.concat(httpLink),
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
    components: { AppNavigation, AppFooter }
  })
})
