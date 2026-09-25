<template>
  <button
    class="button is-danger"
    :disabled="props.photos.length === 0"
    @click="openModal"
  >
    <span class="icon-text">
      <span class="icon"><i class="fas fa-trash"></i></span>
      <span>Delete</span>
    </span>
  </button>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card" ref="modalCard" tabindex="-1">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Delete Photos</p>
        </header>
        <div class="modal-card-body">
          <p>
            Are you sure you want to delete {{ props.photos.length }} photos?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performDelete">
            Delete
          </button>
          <button class="button is-info" @click="closeModal">
            Cancel
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { useModal } from "@/mixins/use-modal";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(["deletePhotos"]);

const { active: modalActive, modalCard, open: openModal, close: closeModal } = useModal();

const performDelete = () => {
  emit("deletePhotos", { ids: props.photos.map((p) => p.id) });
  closeModal();
};
</script>
