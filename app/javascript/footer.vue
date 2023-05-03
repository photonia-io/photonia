<template>
  <footer class="footer mt-5">
    <div class="content has-text-centered">
      <p>
        Photos &copy; <a href="https://www.rusiczki.net">János Rusiczki</a>
      </p>
      <p>
        <router-link :to="{ name: 'tags-index' }">
          <span class="icon-text">
            <span class="icon"><i class="fas fa-tags"></i></span>
            <span>Tags</span>
          </span>
        </router-link>
        &middot;
        <a>
          <span class="icon-text">
            <span class="icon"><i class="fas fa-info-circle"></i></span>
            <span>About</span>
          </span>
        </a>
        &middot;
        <a>
          <span class="icon-text">
            <span class="icon"><i class="fas fa-envelope"></i></span>
            <span>Contact</span>
          </span>
        </a>
        &middot;
        Powered by <a href="https://github.com/janosrusiczki/photonia">Photonia</a>
      </p>
    </div>
  </footer>
</template>
