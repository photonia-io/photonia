<template>
  <nav class="navbar has-shadow" role="navigation" aria-label="main navigation">
    <div class="container">
      <div class="navbar-brand">
        <router-link :to="root_path" class="navbar-item">
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
          <router-link :to="photos_path" class="navbar-item">
            <span class="icon"><i class="fas fa-image"></i></span>
            <span>Photos</span>
          </router-link>

          <router-link :to="albums_path" class="navbar-item">
            <span class="icon"><i class="fas fa-book"></i></span>
            <span>Albums</span>
          </router-link>

          <router-link :to="tags_path" class="navbar-item">
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
            </div>
          </div>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <form :action="photos_path" method="get" accept-charset="UTF-8">
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
  export default {
    data() {
      return {
        root_path: '',
        photos_path: '',
        albums_path: '',
        tags_path: ''
      }
    },
    created() {
      const cj = window.configuration_json
      const cjda = cj.data.attributes
      this.root_path = cjda.root_path
      this.photos_path = cjda.photos_path
      this.albums_path = cjda.albums_path
      this.tags_path = cjda.tags_path
    }
  }
</script>
