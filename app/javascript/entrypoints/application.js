import "@/styles/application.scss";

import { createApp, provide, h, watch } from "vue";
import App from "../app.vue";

import { createRouter, createWebHistory } from "vue-router";

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

document.addEventListener("DOMContentLoaded", () => {
  const userStore = useUserStore(pinia);

  const redirectIfNotSignedIn = (to, from) => {
    if (!userStore.signedIn) {
      return { name: "users-sign-in" };
    }
  };

  const redirectIfUnauthorized = (key) => (to, from) => {
    if (!userStore[key]) {
      toaster("You are not authorized to access that page.", "is-warning");
      return { name: "root" };
    }
  };

  const routes = [
    {
      path: settings.root_path,
      name: "root",
      component: () => import("../homepage/index.vue"),
    },
    {
      path: settings.photos_path,
      name: "photos-index",
      component: () => import("../photos/index.vue"),
    },
    {
      path: settings.photos_path + "/:id",
      name: "photos-show",
      component: () => import("../photos/show.vue"),
    },
    {
      path: settings.albums_path,
      name: "albums-index",
      component: () => import("../albums/index.vue"),
    },
    {
      path: settings.albums_path + "/:id",
      name: "albums-show",
      component: () => import("../albums/show.vue"),
    },
    {
      path: settings.tags_path,
      name: "tags-index",
      component: () => import("../tags/index.vue"),
    },
    {
      path: settings.tags_path + "/:id",
      name: "tags-show",
      component: () => import("../tags/show.vue"),
    },
    {
      path: settings.users_sign_in_path,
      name: "users-sign-in",
      component: () => import("../users/sign-in.vue"),
    },
    {
      path: settings.users_sign_out_path,
      name: "users-sign-out",
      component: () => import("../users/sign-out.vue"),
    },
    {
      path: settings.users_settings_path,
      name: "users-settings",
      component: () => import("../users/settings.vue"),
      beforeEnter: redirectIfNotSignedIn,
    },
    {
      path: settings.users_admin_settings_path,
      name: "users-admin-settings",
      component: () => import("../users/admin-settings.vue"),
      beforeEnter: [redirectIfNotSignedIn, redirectIfUnauthorized("admin")],
    },
    {
      path: settings.photos_path + "/upload",
      name: "photos-upload",
      component: () => import("../photos/upload.vue"),
      beforeEnter: [redirectIfNotSignedIn, redirectIfUnauthorized("uploader")],
    },
    {
      path: settings.photos_path + "/organizer",
      name: "photos-organizer",
      component: () => import("../photos/organizer.vue"),
      beforeEnter: redirectIfNotSignedIn,
    },
    {
      path: settings.photos_path + "/deselected",
      name: "photos-deselected",
      component: () => import("../photos/deselected.vue"),
      beforeEnter: redirectIfNotSignedIn,
    },
    {
      path: settings.stats_path,
      name: "stats-index",
      component: () => import("../stats/index.vue"),
      beforeEnter: redirectIfNotSignedIn,
    },
    {
      path: settings.about_path,
      name: "about",
      component: () => import("../pages/handler.vue"),
    },
    {
      path: settings.privacy_policy_path,
      name: "privacy-policy",
      component: () => import("../pages/handler.vue"),
    },
    {
      path: settings.terms_of_service_path,
      name: "terms-of-service",
      component: () => import("../pages/handler.vue"),
    },
  ];

  const router = createRouter({
    history: createWebHistory(),
    routes,
    scrollBehavior(to, from, savedPosition) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          resolve({ top: 0, behavior: "smooth" });
        }, 50);
      });
    },
  });

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

  const apolloClient = new ApolloClient({
    link: authLink.concat(afterwareLink.concat(httpLink)),
    cache: new InMemoryCache(),
    connectToDevTools: true,
  });

  // if a token was found in local storage, fetch the user

  if (tokenStore.authorization) {
    // we will suppose that the token is valid, later we will check for an error
    userStore.signedIn = true;
    provideApolloClient(apolloClient);
    const { result, error } = useQuery(gql`
      query CurrentUserQuery {
        currentUser {
          id
          email
          admin
          uploader
        }
      }
    `);

    watch(result, (value) => {
      userStore.email = value.currentUser.email;
      userStore.admin = value.currentUser.admin;
      userStore.uploader = value.currentUser.uploader;
    });

    // if the query fails, the token is invalid
    // and the user is not signed in anymore
    watch(error, (value) => {
      if (value && value.graphQLErrors && value.graphQLErrors.length > 0) {
        userStore.signOut();
        toaster(
          "Your session has expired. Please sign in again.",
          "is-warning",
        );
        router.push({ name: "root" });
      }
    });
  }

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
      // Set tracesSampleRate to 1.0 to capture 100%
      // of transactions for performance monitoring.
      // We recommend adjusting this value in production
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
