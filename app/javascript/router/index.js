import { createRouter, createWebHistory } from "vue-router";
import settings from "../mixins/settings";
import toaster from "../mixins/toaster";
import { useUserStore } from "../stores/user";

export function createAppRouter(pinia) {
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
      path: settings.albums_path + "/:id/sort",
      name: "albums-sort",
      component: () => import("../albums/sort.vue"),
      beforeEnter: [redirectIfNotSignedIn],
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

  return router;
}
