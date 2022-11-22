<template>
  <nav class="navbar has-shadow" role="navigation" aria-label="main navigation">
    <div class="container">
      <div class="navbar-brand">
        <router-link :to="{ name: 'root' }" class="navbar-item">
          <img src="/photonia-logo.png" width="156" height="30">
        </router-link>
        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="photonia-navigation">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div id="photonia-navigation" class="navbar-menu">
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
            <form :action="PHOTOS_PATH" method="get" accept-charset="UTF-8">
              <div class="field has-addons">
                <p class="control">
                  <input type="text" name="q" id="q" class="input" placeholder="Find a photo">
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

<script>
  import { useUserStore } from './stores/user'

  export default {
    setup() {
      const userStore = useUserStore()
      return {
        userStore,
      }
    },
    created() {
      this.PHOTOS_PATH = window.configuration_json.data.attributes.photos_path
    }
  }
</script>
