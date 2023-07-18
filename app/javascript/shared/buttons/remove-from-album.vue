<template>
  <button
    class="button"
    :disabled="props.photos.length === 0"
    @click="showModal()"
  >
    <span class="icon-text">
      <span class="icon"><i class="fas fa-folder-minus"></i></span>
      <span>Remove From Album</span>
    </span>
  </button>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Remove From Album</p>
        </header>
        <div class="modal-card-body">
          <RemoveFromAlbumSelect
            ref="removeFromAlbumSelect"
            :photos="props.photos"
          />
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-primary" @click="removeFromAlbum()">
            Remove
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
import { ref, onMounted } from "vue";
import RemoveFromAlbumSelect from "@/albums/remove-from-album-select.vue";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(["removePhotosFromAlbum"]);

const modalActive = ref(false);
const removeFromAlbumSelect = ref();

onMounted(() => {
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      modalActive.value = false;
    }
  });
});

const showModal = () => {
  removeFromAlbumSelect.value.reset();
  modalActive.value = true;
};

const removeFromAlbum = () => {
  const { selectedAlbumId } = removeFromAlbumSelect.value;

  if (selectedAlbumId === "") {
    alert("Please select an album.");
    return;
  }

  const photoIds = props.photos.map((photo) => photo.id);

  emit("removePhotosFromAlbum", {
    albumId: selectedAlbumId,
    photoIds: photoIds,
  });

  modalActive.value = false;
};
</script>
