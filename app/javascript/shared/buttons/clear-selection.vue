<template>
  <button
    class="button is-danger"
    :disabled="disabled"
    @click="modalActive = true"
  >
    <span class="icon">
      <i class="fas fa-times"></i>
    </span>
    <span>Clear Selection</span>
  </button>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Clear Selection</p>
        </header>
        <div class="modal-card-body">
          <p>Are you sure you want to clear the selection?</p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performClearSelection">
            Clear
          </button>
          <button class="button is-info" @click="modalActive = false">
            Cancel
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref } from "vue";

import { useSelectionStore } from "@/stores/selection";

const props = defineProps({
  disabled: {
    type: Boolean,
    required: false,
    default: false,
  },
});

const selectionStore = useSelectionStore();

const modalActive = ref(false);

const performClearSelection = () => {
  modalActive.value = false;
  selectionStore.clearPhotoSelection();
};
</script>
