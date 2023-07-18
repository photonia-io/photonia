<template>
  <button
    class="button is-small"
    @click="router.back()"
  >
    <span class="icon"><i class="fas fa-arrow-left"></i></span>
    <span>Return to the previous page</span>
  </button>
</template>

<script setup>
  import { useRouter } from 'vue-router'
  const router = useRouter()
</script>
