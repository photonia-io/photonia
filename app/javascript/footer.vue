<template>
  <footer class="footer mt-5 pt-5 pb-5">
    <div class="content has-text-centered">
      <p>Photos &copy; <a href="https://www.rusiczki.net">János Rusiczki</a></p>
      <p>
        <router-link :to="{ name: 'tags-index' }">
          <span class="icon-text">
            <span class="icon"><i class="fas fa-tags"></i></span>
            <span>Tags</span>
          </span>
        </router-link>
        &middot;
        <router-link :to="{ name: 'about' }">
          <span class="icon-text">
            <span class="icon"><i class="fas fa-info-circle"></i></span>
            <span>About</span>
          </span>
        </router-link>
        &middot;
        <a>
          <span class="icon-text">
            <span class="icon"><i class="fas fa-envelope"></i></span>
            <span>Contact</span>
          </span>
        </a>
        &middot;
        <router-link :to="{ name: 'privacy-policy' }">
          <span class="icon-text">
            <span class="icon"><i class="fas fa-user-secret"></i></span>
            <span>Privacy Policy</span>
          </span>
        </router-link>
        &middot;
        <router-link :to="{ name: 'terms-of-service' }">
          <span class="icon-text">
            <span class="icon"><i class="fas fa-file-contract"></i></span>
            <span>Terms Of Service</span>
          </span>
        </router-link>
        &middot; Powered by
        <a href="https://github.com/photonia-io/photonia">Photonia</a>
      </p>
    </div>
  </footer>
</template>
