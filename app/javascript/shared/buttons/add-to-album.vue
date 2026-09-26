<template>
  <button
    class="button"
    :class="props.buttonClass"
    :disabled="props.photos.length === 0"
    @click="showModal()"
  >
    <span class="icon"><i class="fas fa-folder-plus"></i></span>
    <span>{{ props.label }}</span>
  </button>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card" ref="modalCard" tabindex="-1">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Add To Album</p>
        </header>
        <div class="modal-card-body">
          <SelectOrCreateAlbum
            ref="selectOrCreateAlbum"
            :photos="props.photos"
            :hide-album-id="props.hideAlbumId"
          />
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <div class="buttons">
            <button class="button is-primary" @click="addToAlbum()">Add</button>
            <button class="button is-info" @click="closeModal">
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
import SelectOrCreateAlbum from "@/albums/select-or-create-album.vue";
import { useModal } from "@/mixins/use-modal";

const props = defineProps({
  photos: {
    type: Array,
    required: true,
  },
  hideAlbumId: {
    type: String,
    required: false,
    default: "",
  },
  // The component has two roots (button + teleport), so attributes don't fall
  // through to the button on their own.
  buttonClass: {
    type: String,
    required: false,
    default: "",
  },
  // Defaults to the wording for a selection of any size; single-photo callers
  // can be more specific.
  label: {
    type: String,
    required: false,
    default: "Add To Album",
  },
});

const emit = defineEmits(["addPhotosToAlbum", "createAlbumWithPhotos"]);

const selectOrCreateAlbum = ref();
const { active: modalActive, modalCard, open: openModal, close: closeModal } = useModal();

const showModal = () => {
  selectOrCreateAlbum.value.reset();
  openModal();
};

const addToAlbum = () => {
  const { selectedAlbumId, newAlbumTitle } = selectOrCreateAlbum.value;

  if (selectedAlbumId === "" && newAlbumTitle === "") {
    alert("Please select an existing album or enter a new album title.");
    return;
  }

  const photoIds = props.photos.map((photo) => photo.id);

  if (selectedAlbumId !== "") {
    // add to existing album
    emit("addPhotosToAlbum", { albumId: selectedAlbumId, photoIds: photoIds });
  }

  if (newAlbumTitle !== "") {
    // create new album
    emit("createAlbumWithPhotos", { title: newAlbumTitle, photoIds: photoIds });
  }

  closeModal();
};
</script>
