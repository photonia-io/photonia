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
      <label for="album-privacy" class="label">Album Privacy:</label>

      <div class="select">
        <select id="album-privacy">
          <option value="public">Public</option>
          <option value="private">Private</option>
        </select>
      </div>

      <label for="album-sorting-type" class="label">Photo Sorting:</label>

      <div class="select is-small">
        <select
          id="album-sorting-type"
          v-model="sortingType"
          @change="updateSorting"
        >
          <option value="takenAt">Date Shot</option>
          <option value="postedAt">Date Uploaded</option>
          <option value="title">Title</option>
          <option value="manual">Manual (custom order)</option>
        </select>
      </div>
      <div class="select is-small ml-2" v-if="sortingType != 'manual'">
        <select
          id="album-sorting-order"
          v-model="sortingOrder"
          @change="updateSorting"
        >
          <option value="asc">{{ sortingOrderAscendingText }}</option>
          <option value="desc">{{ sortingOrderDescendingText }}</option>
        </select>
      </div>

      <button
        class="button is-small ml-2"
        @click="manageSorting"
        v-if="sortingType == 'manual'"
      >
        Manage Sorting
      </button>

      <div class="buttons mt-4">
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
import { computed, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { useApplicationStore } from "../stores/application";

// router
const router = useRouter();

const props = defineProps({
  album: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["deleteAlbum", "updateSorting"]);
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

const sortingType = ref("takenAt");
const sortingOrder = ref("asc");

// Initialize sorting values from album prop
watch(
  () => props.album,
  (newAlbum) => {
    if (newAlbum) {
      sortingType.value = newAlbum.sortingType || "takenAt";
      sortingOrder.value = newAlbum.sortingOrder || "asc";
    }
  },
  { immediate: true },
);

const updateSorting = () => {
  emit("updateSorting", {
    id: props.album.id,
    sortingType: sortingType.value,
    sortingOrder: sortingOrder.value,
  });
};

const sortingOrderAscendingText = computed(() => {
  return sortingType.value != "title" ? "Oldest First" : "A - Z";
});

const sortingOrderDescendingText = computed(() => {
  return sortingType.value != "title" ? "Newest First" : "Z - A";
});

const manageSorting = () => {
  applicationStore.stopEditingAlbum();
  router.push({
    name: "albums-sort",
    params: { id: props.album.id },
  });
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
