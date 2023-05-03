<template>
  <div class="message is-warning">
    <div class="message-header">
      <p>Photo Administration</p>
    </div>
    <div class="message-body">
      <!-- delete photo button -->
      <button class="button is-danger" @click="showConfirmationModal">Delete Photo</button>
    </div>
  </div>
  <teleport to="#modal-root">
    <div
      :class="['modal', modalActive ? 'is-active' : null]"
    >
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Delete Photo</p>
        </header>
        <div class="modal-card-body">
          <p>Are you sure you want to delete this photo?</p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performDelete">Delete</button>
          <button class="button is-info" @click="closeConfirmationModal">Cancel</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
  import { ref } from 'vue'
  import { useApplicationStore } from '../stores/application'

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    },
    loading: {
      type: Boolean,
      required: true
    }
  })

  const emit = defineEmits(['deletePhoto'])
  const applicationStore = useApplicationStore()

  const modalActive = ref(false)

  const showConfirmationModal = () => {
    modalActive.value = true
    applicationStore.disableNavigationShortcuts()
  }

  const closeConfirmationModal = () => {
    modalActive.value = false
    applicationStore.enableNavigationShortcuts()
  }

  const performDelete = () => {
    emit('deletePhoto', { id: props.photo.id })
    closeConfirmationModal()
  }
</script>
