import "@/styles/application.scss";

import { createApp, provide, h, watch } from "vue";
import App from "../app.vue";

import { createAppRouter } from "../router";

import { createPinia } from "pinia";
const pinia = createPinia();

import { pageTitle } from "vue-page-title";

import {
  ApolloClient,
  createHttpLink,
  ApolloLink,
  InMemoryCache,
} from "@apollo/client/core";
import { setContext } from "@apollo/client/link/context";
import {
  DefaultApolloClient,
  provideApolloClient,
  useQuery,
} from "@vue/apollo-composable";
import gql from "graphql-tag";

import { useTokenStore } from "../stores/token";
import { useUserStore } from "../stores/user";

import toaster from "../mixins/toaster";
import settings from "../mixins/settings";

import * as Sentry from "@sentry/vue";

document.addEventListener("DOMContentLoaded", async () => {
  const userStore = useUserStore(pinia);

  const tokenStore = useTokenStore(pinia);

  const httpLink = createHttpLink({ uri: settings.graphql_path });
  const authLink = setContext((_, { headers }) => {
    return {
      headers: {
        ...headers,
        authorization: tokenStore.authorization,
      },
    };
  });

  const afterwareLink = new ApolloLink((operation, forward) => {
    return forward(operation).map((response) => {
      const context = operation.getContext();
      const headers = context.response.headers;
      const authorization = headers.get("Authorization");
      if (authorization) {
        tokenStore.$patch({ authorization });
      }
      return response;
    });
  });

  const cache = new InMemoryCache({
    typePolicies: {
      Photo: {
        fields: {
          userTags: {
            merge(existing, incoming) {
              return incoming;
            },
          },
          machineTags: {
            merge(existing, incoming) {
              return incoming;
            },
          },
        },
      },
    },
  });

  const apolloClient = new ApolloClient({
    link: authLink.concat(afterwareLink.concat(httpLink)),
    cache,
    connectToDevTools: true,
  });

  // if a token was found in local storage, fetch the user synchronously before router initialization

  if (tokenStore.authorization) {
    provideApolloClient(apolloClient);

    try {
      const { data } = await apolloClient.query({
        query: gql`
          query CurrentUserQuery {
            currentUser {
              id
              email
              admin
              uploader
            }
          }
        `,
      });

      userStore.signedIn = true;
      userStore.email = data.currentUser.email;
      userStore.admin = data.currentUser.admin;
      userStore.uploader = data.currentUser.uploader;
    } catch (error) {
      if (error && error.graphQLErrors && error.graphQLErrors.length > 0) {
        userStore.signOut();
        toaster(
          "Your session has expired. Please sign in again.",
          "is-warning",
        );
      }
    }
  }

  // Initialize router after user data is loaded
  const router = createAppRouter(pinia);

  // go for Vue!

  const app = createApp({
    setup() {
      provide(DefaultApolloClient, apolloClient);
    },
    render: () => h(App),
  });

  app.provide("apolloClient", apolloClient);

  app.config.globalProperties.gql_queries = window.gql_queries;
  app.config.globalProperties.gql_cached_query = window.gql_cached_query;
  app.config.globalProperties.gql_cached_result = window.gql_cached_result;

  // Start Sentry

  if (import.meta.env.PROD) {
    Sentry.init({
      app,
      dsn: settings.sentry_dsn,
      integrations: [
        Sentry.browserTracingIntegration({ router }),
        Sentry.replayIntegration(),
      ],
      tracesSampleRate: settings.sentry_sample_rate,
      tracePropagationTargets: ["photos.rusiczki.net", /^\//],
    });
  }

  app.use(router);
  app.use(pinia);

  app.use(
    pageTitle({
      suffix: settings.site_name,
      separator: " - ",
      mixin: true,
    }),
  );

  app.mount("#app");
});
