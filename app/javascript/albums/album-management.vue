<template>
  <div class="message is-warning is-smallish">
    <div class="message-header">
      <p>Album Management</p>
    </div>
    <div class="message-body">
      <p class="mb-3">
        To edit the album's title or description click / tap on the texts
        themselves.
      </p>

      <div class="buttons">
        <button class="button is-danger" @click="showConfirmationModal">
          Delete Album
        </button>
      </div>
    </div>
  </div>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Delete Album</p>
        </header>
        <div class="modal-card-body">
          <p>
            Are you sure you want to delete this album? This will not delete the
            photos inside the album, but the album itself will be gone forever.
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="performDelete">
              Delete
            </button>
            <button class="button is-info" @click="closeConfirmationModal">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref } from "vue";
import { useApplicationStore } from "../stores/application";

const props = defineProps({
  album: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["deleteAlbum"]);
const applicationStore = useApplicationStore();

const modalActive = ref(false);

const showConfirmationModal = () => {
  modalActive.value = true;
  applicationStore.disableNavigationShortcuts();
};

const closeConfirmationModal = () => {
  modalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const performDelete = () => {
  emit("deleteAlbum", { id: props.album.id });
  closeConfirmationModal();
};
</script>

<style scoped>
.message.is-smallish {
  font-size: 0.84rem;
}

.message-body {
  padding: 1em 1em;
}
</style>
