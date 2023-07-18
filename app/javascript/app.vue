<template>
  <div>
    <Navigation></Navigation>
    <RouterView></RouterView>
    <Footer></Footer>
  </div>
</template>

<script>
import Navigation from "./navigation.vue";
import Footer from "./footer.vue";

export default {
  name: "App",
  components: {
    Navigation,
    Footer,
  },
};
</script>
