<template>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card" ref="modalCard" tabindex="-1">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">
            Selected Photos ({{ selectionStore.count }})
          </p>
        </header>
        <div class="modal-card-body">
          <p v-if="selectionStore.count === 0">Nothing selected.</p>
          <div v-else class="selection-drawer-grid">
            <div
              v-for="photo in selectionStore.selected"
              :key="photo.id"
              class="selection-drawer-item"
            >
              <img v-if="photo.thumbnailUrl" :src="photo.thumbnailUrl" :alt="photo.title" />
              <button
                type="button"
                class="delete is-small selection-drawer-remove"
                :aria-label="`Deselect ${photo.title}`"
                @click="selectionStore.remove(photo)"
              ></button>
              <p class="is-size-7 selection-drawer-title">{{ photo.title }}</p>
            </div>
          </div>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-danger" @click="clearAndClose">Clear All</button>
            <button class="button is-info" @click="closeModal">Close</button>
          </div>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { onMounted } from "vue";

import { useSelectionStore } from "@/stores/selection";
import { useModal } from "@/mixins/use-modal";

const emit = defineEmits(["close"]);

const selectionStore = useSelectionStore();
const { active: modalActive, modalCard, open: openModal, close: closeModal } = useModal({
  onClose: () => emit("close"),
});

onMounted(openModal);

const clearAndClose = () => {
  selectionStore.clear();
  closeModal();
};
</script>

<style>
.selection-drawer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 0.75rem;
}

.selection-drawer-item {
  position: relative;
}

.selection-drawer-item img {
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: cover;
  border-radius: 3px;
}

.selection-drawer-remove {
  position: absolute;
  top: 0.35rem;
  right: 0.35rem;
}

.selection-drawer-title {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
