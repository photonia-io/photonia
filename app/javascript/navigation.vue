<template>
  <nav class="navbar has-shadow" role="navigation" aria-label="main navigation">
    <div class="container">
      <div class="navbar-brand">
        <router-link :to="{ name: 'root' }" class="navbar-item">
          <img src="@/assets/photonia-logo.png" width="156" height="30">
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
            <span class="icon"><i class="fas fa-image"></i></span>
            <span>Photos</span>
          </router-link>

          <router-link :to="{ name: 'albums-index' }" class="navbar-item">
            <span class="icon"><i class="fas fa-book"></i></span>
            <span>Albums</span>
          </router-link>

          <router-link :to="{ name: 'tags-index' }" class="navbar-item">
            <span class="icon"><i class="fas fa-tag"></i></span>
            <span>Tags</span>
          </router-link>

          <div class="navbar-item has-dropdown is-hoverable">
            <a class="navbar-link">
              More
            </a>
            <div class="navbar-dropdown">
              <a class="navbar-item">
                About
              </a>
              <a class="navbar-item">
                Contact
              </a>
              <hr class="navbar-divider">
              <!-- <%= link_to 'Upload', new_photo_path, class: 'navbar-item' %> -->
              <router-link
                v-if="userStore.signedIn"
                :to="{ name: 'users-settings' }"
                class="navbar-item"
              >
                Settings
              </router-link>
              <router-link
                v-if="userStore.signedIn"
                :to="{ name: 'users-sign-out' }"
                class="navbar-item"
              >
                Sign Out
              </router-link>
              <router-link
                v-if="!userStore.signedIn"
                :to="{ name: 'users-sign-in' }"
                class="navbar-item"
              >
                Sign In
              </router-link>
            </div>
          </div>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <form @submit.prevent="doSearch">
              <div class="field has-addons">
                <p class="control">
                  <input
                    type="text"
                    class="input"
                    placeholder="Find a photo"
                    v-model="query"
                  >
                </p>
                <p class="control">
                  <input type="submit" class="button" value="Search">
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
  import { ref, watch } from 'vue'
  import { useUserStore } from './stores/user'
  import { useRoute, useRouter } from 'vue-router'


  const router = useRouter()
  const userStore = useUserStore()

  const showNavigation = ref(false)
  const query = ref('')

  watch(useRoute(), (route) => {
    query.value = route.query.q
  });

  function doSearch() {
    const routeQuery = query.value ? { q: query.value } : {}
    router.push({ name: 'photos-index', query: routeQuery })
  }
</script>
