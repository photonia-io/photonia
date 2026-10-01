import { createRouter, createWebHistory } from "vue-router";
import settings from "../mixins/settings";
import toaster from "../mixins/toaster";
import { useUserStore } from "../stores/user";
import { useApplicationStore } from "../stores/application";
import { onlyLightboxToggled } from "../mixins/use-lightbox-route";

export function createAppRouter(pinia) {
  const userStore = useUserStore(pinia);
  const applicationStore = useApplicationStore(pinia);

  const redirectIfNotSignedIn = (to, from) => {
    if (!userStore.signedIn) {
      toaster("You need to sign in to access that page.", "is-warning");
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
      path: settings.admin_path,
      name: "admin",
      component: () => import("../admin/index.vue"),
      beforeEnter: [redirectIfNotSignedIn, redirectIfUnauthorized("admin")],
      redirect: { name: "admin-general" },
      children: [
        {
          path: "general",
          name: "admin-general",
          component: () => import("../admin/general.vue"),
        },
        {
          path: "homepage",
          name: "admin-homepage",
          component: () => import("../admin/homepage.vue"),
        },
        {
          path: "comments",
          name: "admin-comments",
          component: () => import("../admin/comments.vue"),
        },
        {
          path: "system",
          name: "admin-system",
          component: () => import("../admin/system.vue"),
        },
        {
          path: "users",
          name: "admin-users",
          component: () => import("../admin/users.vue"),
        },
        {
          path: "users/:id",
          name: "admin-show-user",
          component: () => import("../admin/show-user.vue"),
        },
      ],
    },
    {
      path: settings.photos_path + "/upload",
      name: "photos-upload",
      component: () => import("../photos/upload.vue"),
      beforeEnter: [redirectIfNotSignedIn, redirectIfUnauthorized("uploader")],
    },
    {
      path: settings.photos_path + "/search",
      name: "photos-search",
      component: () => import("../photos/search.vue"),
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
      // Starting/stopping album navigation only changes the query string on the
      // photo we are already looking at - don't yank the page to the top.
      const sameShownPhoto =
        to.name === "photos-show" &&
        from.name === "photos-show" &&
        to.params.id === from.params.id;
      if (sameShownPhoto) return false;

      // Submitting a search only changes the query string on the page
      // we're already looking at - don't yank the user back to the top of
      // a long filter form, away from the results they just asked for.
      const sameSearch = to.name === "photos-search" && from.name === "photos-search";
      if (sameSearch) return false;

      return new Promise((resolve, reject) => {
        setTimeout(() => {
          resolve({ top: 0, behavior: "smooth" });
        }, 50);
      });
    },
  });

  router.beforeEach((to, from) => {
    // Opening/closing the lightbox only toggles ?lightbox= on the photo
    // already being shown - never worth an "are you sure" prompt.
    if (onlyLightboxToggled(to, from)) return;

    // Will trigger when editing a photo or album's details
    if (applicationStore.editing) {
      applicationStore.openNavigationModal(
        to,
        "You are modifying something. Are you sure you want to navigate away?",
        "stopEditing",
      );
      return false;
    }
  });

  return router;
}
