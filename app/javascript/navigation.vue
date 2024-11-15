<template>
  <nav class="navbar has-shadow" role="navigation" aria-label="main navigation">
    <div class="container">
      <div class="navbar-brand">
        <router-link :to="{ name: 'root' }" class="navbar-item">
          <picture>
            <source
              v-if="applicationStore.colorScheme === 'dark'"
              srcset="@/assets/photonia-logo-dark.png"
              width="156"
              height="24"
            />
            <source
              v-else
              srcset="@/assets/photonia-logo-light.png"
              width="156"
              height="24"
            />
            <img
              src="@/assets/photonia-logo-light.png"
              width="156"
              height="24"
            />
          </picture>
        </router-link>
        <a
          role="button"
          class="navbar-burger burger"
          v-on:click="showNavigation = !showNavigation"
        >
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div
        id="photonia-navigation"
        class="navbar-menu"
        :class="{ 'is-active': showNavigation }"
      >
        <div class="navbar-start">
          <router-link :to="{ name: 'photos-index' }" class="navbar-item">
            <span class="icon-text">
              <span class="icon"><i class="fas fa-image"></i></span>
              <span>Photos</span>
            </span>
          </router-link>

          <router-link :to="{ name: 'albums-index' }" class="navbar-item">
            <span class="icon-text">
              <span class="icon"><i class="fas fa-book"></i></span>
              <span>Albums</span>
            </span>
          </router-link>

          <router-link
            v-if="userStore.signedIn && userStore.uploader"
            :to="{ name: 'photos-upload' }"
            class="navbar-item"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-upload"></i></span>
              <span>Upload</span>
            </span>
          </router-link>

          <router-link
            v-if="userStore.signedIn && userStore.admin"
            :to="{ name: 'stats-index' }"
            class="navbar-item"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-chart-line"></i></span>
              <span>Stats</span>
            </span>
          </router-link>

          <router-link
            v-if="userStore.signedIn"
            :to="{ name: 'users-settings' }"
            class="navbar-item"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-cog"></i></span>
              <span>Settings</span>
            </span>
          </router-link>

          <router-link
            v-if="userStore.signedIn"
            :to="{ name: 'users-sign-out' }"
            class="navbar-item"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-sign-out-alt"></i></span>
              <span>Sign Out</span>
            </span>
          </router-link>

          <router-link
            v-if="!userStore.signedIn"
            :to="{ name: 'users-sign-in' }"
            class="navbar-item"
          >
            <span class="icon-text">
              <span class="icon"><i class="fas fa-sign-in-alt"></i></span>
              <span>Sign In</span>
            </span>
          </router-link>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <span
              v-if="applicationStore.colorScheme === 'dark'"
              class="icon is-clickable"
              @click="applicationStore.setUserColorScheme('light')"
            >
              <i class="fas fa-moon"></i>
            </span>
            <span
              v-else
              class="icon is-clickable"
              @click="applicationStore.setUserColorScheme('dark')"
            >
              <i class="fas fa-sun"></i>
            </span>
          </div>
          <div class="navbar-item">
            <form @submit.prevent="doSearch">
              <div class="field has-addons">
                <p class="control">
                  <input
                    type="text"
                    class="input"
                    placeholder="Find a photo"
                    v-model="query"
                  />
                </p>
                <p class="control">
                  <input type="submit" class="button" value="Search" />
                </p>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, watch } from "vue";
import { useApplicationStore } from "@/stores/application";
import { useUserStore } from "@/stores/user";
import { useRoute, useRouter } from "vue-router";

const router = useRouter();
const applicationStore = useApplicationStore();
const userStore = useUserStore();

const showNavigation = ref(false);
const query = ref("");

watch(useRoute(), (route) => {
  query.value = route.query.q;
});

function doSearch() {
  const routeQuery = query.value ? { q: query.value } : {};
  router.push({ name: "photos-index", query: routeQuery });
}
</script>
