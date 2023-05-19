<template>
  <button
    class="button is-danger"
    :disabled="props.photos.length === 0"
    @click="modalActive = true"
  >
    <span class="icon-text">
      <span class="icon"><i class="fas fa-trash"></i></span>
      <span>Delete</span>
    </span>
  </button>
  <teleport to="#modal-root">
    <div
      :class="['modal', modalActive ? 'is-active' : null]"
    >
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Delete Photos</p>
        </header>
        <div class="modal-card-body">
          <p>Are you sure you want to delete {{ props.photos.length }} photos?</p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performDelete">Delete</button>
          <button class="button is-info" @click="modalActive = false">Cancel</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
  import { ref } from 'vue'

  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })

  const modalActive = ref(false)
</script>
