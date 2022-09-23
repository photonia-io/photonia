<template>
  <div>
    <Navigation></Navigation>
    <section class="section pt-5">
      <div class="container is-dark">
        <RouterView></RouterView>
      </div>
    </section>
    <Footer></Footer>
  </div>
</template>

<script>
import Navigation from './navigation.vue'
import Footer from './footer.vue'

export default {
  name: 'App',
  components: {
    Navigation,
    Footer
  }
}
</script>

<style>

</style>
