<template>
  <div class="message is-warning is-smallish">
    <div class="message-header">
      <p>Album Management</p>
    </div>
    <div class="message-body">
      <p>
        To edit the album's title or description click / tap on the texts
        themselves.
      </p>

      <label for="album-privacy" class="label mt-4">Album Privacy:</label>
      <div class="select">
        <select id="album-privacy" v-model="privacy" @change="setPrivacy">
          <option value="public">Public</option>
          <option value="friends_and_family">Friends & Family</option>
          <option value="private">Private</option>
        </select>
      </div>

      <label for="album-sorting-type" class="label mt-4">Photo Sorting:</label>
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

      <div class="buttons mt-5">
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
  <teleport to="#modal-root">
    <div :class="['modal', privacyModalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">
            Change Album Privacy to Private
          </p>
        </header>
        <div class="modal-card-body">
          <p>
            When you set this album to Private,
            <strong>{{ album.privatizablePhotosCount }}</strong>
            {{ album.privatizablePhotosCount === 1 ? "photo" : "photos" }}
            contained in this album will also be set to Private.
          </p>
          <p class="mt-3">Do you want to continue?</p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-warning" @click="confirmPrivacyChange">
            Yes, set album and photos to Private
          </button>
          <button class="button is-info" @click="cancelPrivacyChange">
            Cancel
          </button>
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

const emit = defineEmits(["deleteAlbum", "updateSorting", "setAlbumPrivacy"]);
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
const privacy = ref("public");
// The privacy last confirmed by the server, so Cancel has something to revert to
const committedPrivacy = ref("public");

// Initialize sorting values from album prop
watch(
  () => props.album,
  (newAlbum) => {
    if (newAlbum) {
      sortingType.value = newAlbum.sortingType || "takenAt";
      sortingOrder.value = newAlbum.sortingOrder || "asc";
      const p = newAlbum.privacy || "public";
      privacy.value = p;
      committedPrivacy.value = p;
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

const privacyModalActive = ref(false);

const setPrivacy = () => {
  const newPrivacy = privacy.value;

  // Cascading to photos only makes sense when going private and there's
  // something in the album to cascade to
  const needsConfirmation =
    newPrivacy === "private" &&
    committedPrivacy.value !== "private" &&
    (props.album.privatizablePhotosCount ?? 0) > 0;

  if (needsConfirmation) {
    privacyModalActive.value = true;
    applicationStore.disableNavigationShortcuts();
  } else {
    emit("setAlbumPrivacy", {
      id: props.album.id,
      privacy: newPrivacy,
      updatePhotos: false,
    });
  }
};

const confirmPrivacyChange = () => {
  emit("setAlbumPrivacy", {
    id: props.album.id,
    privacy: privacy.value,
    updatePhotos: true,
  });
  privacyModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const revertPrivacy = () => {
  privacy.value = committedPrivacy.value;
};

const cancelPrivacyChange = () => {
  revertPrivacy();
  privacyModalActive.value = false;
  applicationStore.enableNavigationShortcuts();
};

const sortingOrderAscendingText = computed(() => {
  return sortingType.value != "title" ? "Oldest First" : "A - Z";
});

const sortingOrderDescendingText = computed(() => {
  return sortingType.value != "title" ? "Newest First" : "Z - A";
});

const manageSorting = () => {
  router.push({
    name: "albums-sort",
    params: { id: props.album.id },
  });
};

const performDelete = () => {
  emit("deleteAlbum", { id: props.album.id });
  closeConfirmationModal();
};

defineExpose({ revertPrivacy });
</script>

<style scoped>
.message.is-smallish {
  font-size: 0.84rem;
}

.message-body {
  padding: 1em 1em;
}
</style>
