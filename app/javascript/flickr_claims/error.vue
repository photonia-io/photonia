<template>
  <div class="container">
    <div class="section">
      <div class="box has-text-centered">
        <div class="icon-text is-flex-direction-column">
          <span class="icon has-text-danger is-size-1 mb-4">
            <i class="fas fa-exclamation-triangle"></i>
          </span>
          <h1 class="title is-3 has-text-danger">Error</h1>
        </div>
        <p class="mt-4" v-if="errorMessage">
          {{ errorMessage }}
        </p>
        <p class="mt-4" v-else>
          An error occurred while processing your request.
        </p>
        <div class="mt-5">
          <router-link to="/" class="button is-primary">
            <span class="icon">
              <i class="fas fa-home"></i>
            </span>
            <span>Go to Homepage</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();
const errorMessage = ref(route.query.error || "");
</script>
