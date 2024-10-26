<template>
  <div>
    <Navigation></Navigation>
    <RouterView></RouterView>
    <Footer></Footer>
  </div>
</template>

<script setup>
import Navigation from "./navigation.vue";
import Footer from "./footer.vue";

import { useApplicationStore } from "@/stores/application";
import { watch } from "vue";
import { storeToRefs } from "pinia";

const applicationStore = useApplicationStore();
const { colorScheme } = storeToRefs(applicationStore);

function setColorScheme(cs) {
  document.documentElement.setAttribute("data-theme", cs);
}

watch(colorScheme, (cs) => {
  setColorScheme(cs);
});

setColorScheme(colorScheme.value);
</script>
