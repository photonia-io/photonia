<template>
  <div class="message is-warning is-smallish">
    <div class="message-header">
      <p>Photo Management</p>
    </div>
    <div class="message-body">
      <p class="mb-3">
        To edit the photo's title or description click / tap on the texts
        themselves.
      </p>
      <!-- edit thumbnail button -->
      <button class="button is-info mb-3" @click="editThumbnail">
        <span class="icon">
          <i class="fas fa-crop"></i>
        </span>
        <span>Edit Thumbnail</span>
      </button>
      <!-- delete photo button -->
      <button class="button is-danger" @click="showConfirmationModal">
        Delete Photo
      </button>
    </div>
  </div>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Delete Photo</p>
        </header>
        <div class="modal-card-body">
          <p>Are you sure you want to delete this photo?</p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performDelete">
            Delete
          </button>
          <button class="button is-info" @click="closeConfirmationModal">
            Cancel
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref } from "vue";
import { useApplicationStore } from "../stores/application";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["deletePhoto", "editThumbnail"]);
const applicationStore = useApplicationStore();

const modalActive = ref(false);

const editThumbnail = () => {
  emit("editThumbnail");
};

const showConfirmationModal = () => {
  modalActive.value = true;
  applicationStore.disableNavigationShortcuts();
};

const closeConfirmationModal = () => {
  modalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const performDelete = () => {
  emit("deletePhoto", { id: props.photo.id });
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
