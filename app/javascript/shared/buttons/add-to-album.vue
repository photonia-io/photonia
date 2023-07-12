<template>
  <button
    class="button"
    :disabled="props.photos.length === 0"
    @click="showModal()"
  >
    <span class="icon-text">
      <span class="icon"><i class="fas fa-folder-plus"></i></span>
      <span>Add To Album</span>
    </span>
  </button>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Add To Album</p>
        </header>
        <div class="modal-card-body">
          <SelectOrCreateAlbum ref="selectOrCreateAlbum" />
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-primary" @click="addToAlbum()">Add</button>
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
import SelectOrCreateAlbum from "@/albums/select-or-create-album.vue";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(["addPhotosToAlbum", "createAlbumWithPhotos"]);

const modalActive = ref(false);
const selectOrCreateAlbum = ref();

onMounted(() => {
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      modalActive.value = false;
    }
  });
});

const showModal = () => {
  selectOrCreateAlbum.value.reset();
  modalActive.value = true;
};

const addToAlbum = () => {
  const { selectedAlbumId, newAlbumTitle } = selectOrCreateAlbum.value;

  if (selectedAlbumId === "" && newAlbumTitle === "") {
    alert("Please select an existing album or enter a new album title.");
    return;
  }

  const photoIds = props.photos.map((photo) => photo.id);

  debugger;

  if (selectedAlbumId !== "") {
    // add to existing album
    emit("addPhotosToAlbum", { albumId: selectedAlbumId, photoIds: photoIds });
  }

  if (newAlbumTitle !== "") {
    // create new album
    emit("createAlbumWithPhotos", { title: newAlbumTitle, photoIds: photoIds });
  }

  modalActive.value = false;
};
</script>
