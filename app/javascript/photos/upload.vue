<template>
  <div class="container">
    <h1 class="title mt-5 mb-0">Upload Photos</h1>
    <hr class="mt-2 mb-4" />

    <!-- NEW: Batch Album Selection (shows when files are queued) -->
    <div class="box" v-show="files.length > 0 && !uploadStarted">
      <h2 class="subtitle">Album Association (applies to all files)</h2>
      <select-or-create-album ref="albumSelector" />
    </div>

    <!-- Info message when upload has started -->
    <div class="notification is-info" v-if="uploadStarted">
      <p v-if="!allUploadsComplete">
        <strong>Upload in progress.</strong>
        Once all uploads complete, click the "Remove Uploaded" button to clear
        files and reset the form for the next batch.
      </p>
      <p v-else>
        <strong>Uploads complete.</strong>
        Click the "Remove Uploaded" button to clear files and reset the form for
        the next batch.
      </p>
    </div>

    <div v-show="$refs.upload && $refs.upload.dropActive" class="drop-active">
      <h3>Drop files here to upload</h3>
    </div>
    <div v-show="!files.length" class="block drop-zone has-text-centered">
      <h4>Drop files anywhere to upload<br />or</h4>
      <label for="photo[image]" class="button is-primary">
        <span class="icon is-small">
          <i class="fa fa-plus" aria-hidden="true"></i>
        </span>
        <span>Select Files</span>
      </label>
    </div>
    <div class="box" v-for="file in files" :key="file.id">
      <div class="columns">
        <div class="column is-12" v-if="file.active">
          <progress
            class="progress is-small is-primary"
            :value="file.progress"
            max="100"
          >
            {{ file.progress }}%
          </progress>
        </div>
      </div>
      <div class="columns">
        <div class="column is-2">
          <img
            v-if="file.thumb"
            :src="file.thumb"
            :alt="file.name"
            style="max-width: 100%; max-height: 100%"
          />
        </div>
        <div class="column is-10">
          <div class="columns">
            <div class="column is-half">
              <input
                type="text"
                class="input is-small"
                v-model="file.data['photo[title]']"
              />
              <textarea
                class="textarea is-small"
                v-model="file.data['photo[description]']"
              >
              </textarea>
            </div>
            <div class="column is-half">
              <p class="mb-2">
                <span>Size: {{ formatSize(file.size) }}</span>
              </p>
              <p class="mb-2">
                Status:
                <span class="icon-text has-text-danger" v-if="file.error">
                  <span class="icon">
                    <i class="fas fa-exclamation-triangle"></i>
                  </span>
                  Error: {{ uploadErrorMessage(file) }}
                </span>
                <span
                  class="icon-text has-text-success"
                  v-else-if="file.success"
                >
                  <span class="icon">
                    <i class="fas fa-check"></i>
                  </span>
                  Uploaded Successfully
                </span>
                <span class="icon-text" v-else-if="file.active">
                  <span class="icon">
                    <i class="fas fa-spinner fa-pulse"></i>
                  </span>
                  Uploading...
                </span>
                <span
                  class="icon-text has-text-danger"
                  v-else-if="!!file.error"
                >
                  <span class="icon">
                    <i class="fas fa-exclamation-triangle"></i>
                  </span>
                  {{ file.error }}
                </span>
                <span v-else>Ready to upload</span>
              </p>
              <div class="buttons">
                <button
                  type="button"
                  class="button is-danger"
                  @click.prevent="$refs.uploader.remove(file)"
                >
                  <span class="icon is-small">
                    <i class="fa fa-trash" aria-hidden="true"></i>
                  </span>
                  <span>Remove</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="columns">
      <div class="column is-half">
        <div class="buttons">
          <file-upload
            name="photo[image]"
            class="button is-primary"
            :class="{ 'is-static': uploadStarted }"
            :aria-disabled="uploadStarted ? 'true' : 'false'"
            :style="{
              pointerEvents: uploadStarted ? 'none' : null,
              opacity: uploadStarted ? 0.6 : 1,
            }"
            post-action="/photos"
            extensions="jpg,jpeg,png,gif,webp"
            accept="image/jpeg,image/png,image/gif,image/webp"
            :multiple="true"
            :headers="{ Authorization: tokenStore.authorization }"
            v-model="files"
            @input-filter="inputFilter"
            @input-file="handleFileInput"
            ref="uploader"
            :drop="true"
            :disabled="uploadStarted"
          >
            <span class="icon is-small">
              <i class="fa fa-plus" aria-hidden="true"></i>
            </span>
            <span>Select Files</span>
          </file-upload>
          <button
            type="button"
            class="button is-success"
            v-if="!uploader || !uploader.active"
            @click.prevent="startUpload"
            :disabled="files.length === 0 || uploadStarted"
          >
            <span class="icon is-small">
              <i class="fa fa-arrow-up" aria-hidden="true"></i>
            </span>
            <span>Upload All</span>
          </button>
          <button
            type="button"
            class="btn btn-danger"
            v-else
            @click.prevent="uploader.active = false"
            :disabled="!uploadStarted"
          >
            <span class="icon is-small">
              <i class="fa fa-stop" aria-hidden="true"></i>
            </span>
            <span>Stop Upload</span>
          </button>
        </div>
      </div>
      <div class="column is-half">
        <div class="buttons is-pulled-right">
          <button
            type="button"
            class="button is-danger"
            @click.prevent="$refs.uploader.clear()"
            :disabled="files.length === 0 || uploadStarted"
          >
            <span class="icon is-small">
              <i class="fa fa-trash" aria-hidden="true"></i>
            </span>
            <span>Remove All</span>
          </button>
          <button
            type="button"
            class="button is-danger"
            @click.prevent="removeUploadedFiles()"
            :disabled="!allUploadsComplete"
          >
            <span class="icon is-small">
              <i class="fa fa-broom" aria-hidden="true"></i>
            </span>
            <span>Remove Uploaded</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.drop-zone {
  background-color: #f5f5f5;
  border: 2px dashed #ccc;
  border-radius: 5px;
  padding: 20px;
  text-align: center;
}
</style>

<script setup>
import { computed, ref, watch } from "vue";

import { useTokenStore } from "../stores/token.js";
import { useTitle } from "vue-page-title";
import FileUpload from "vue-upload-component";
import SelectOrCreateAlbum from "../albums/select-or-create-album.vue";

useTitle("Upload Photos");

const uploader = ref(null);
const files = ref([]);
const tokenStore = useTokenStore();
const albumSelector = ref(null);
const uploadStarted = ref(false);

const allUploadsComplete = computed(() => {
  // Upload must have started and every file must be either successful or errored
  if (!uploadStarted.value || files.value.length === 0) return false;
  return files.value.every((file) => file.success || file.error);
});

// When all uploads complete, refresh the album picker (single request via child component).
watch(
  allUploadsComplete,
  async (val) => {
    if (val && albumSelector.value?.refetch) {
      try {
        await albumSelector.value.refetch();
      } catch (e) {
        // ignore refetch errors - not critical for upload success
      }
    }
  },
  { immediate: false },
);

// Watch for changes in album selection and update all files
watch(
  () => [
    albumSelector.value?.selectedAlbumId,
    albumSelector.value?.newAlbumTitle,
  ],
  () => {
    updateAllFilesWithAlbumData();
  },
  { deep: true },
);

const applyAlbumDataToFile = (file) => {
  if (!albumSelector.value) return;
  if (!file.data) file.data = {};

  const selectedAlbumId = albumSelector.value.selectedAlbumId;
  const newAlbumTitle = albumSelector.value.newAlbumTitle;

  // Clear previous album data
  delete file.data["photo[album_ids][]"];
  delete file.data["photo[new_album_titles][]"];

  // Set new album data
  if (selectedAlbumId) {
    file.data["photo[album_ids][]"] = [selectedAlbumId];
  } else if (newAlbumTitle) {
    file.data["photo[new_album_titles][]"] = [newAlbumTitle];
  }
};

const updateAllFilesWithAlbumData = () => {
  files.value.forEach((file) => {
    applyAlbumDataToFile(file);
  });
};

const inputFilter = function (newFile, oldFile, prevent) {
  if (newFile && !oldFile) {
    if (/(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/.test(newFile.name)) {
      return prevent();
    }

    if (/\.(php5?|html?|jsx?)$/i.test(newFile.name)) {
      return prevent();
    }

    if (
      newFile &&
      newFile.error === "" &&
      newFile.file &&
      (!oldFile || newFile.file !== oldFile.file)
    ) {
      // Create a blob field
      newFile.blob = "";
      let URL = window.URL || window.webkitURL;
      if (URL) {
        newFile.blob = URL.createObjectURL(newFile.file);
      }
      // Thumbnails
      newFile.thumb = "";
      if (newFile.blob && newFile.type.substr(0, 6) === "image/") {
        newFile.thumb = newFile.blob;
      }
      // Add some extra info
      newFile.data = {
        "photo[title]": newFile.name,
      };

      // Apply current album selection to new file
      applyAlbumDataToFile(newFile);
    }
  }
};

// Handle successful upload response
const handleUploadSuccess = async (file, response) => {
  if (response.created_album_ids && response.created_album_ids.length > 0) {
    // Update remaining files to use the created album ID instead of title
    const createdId = response.created_album_ids[0];
    const newAlbumTitle = albumSelector.value?.newAlbumTitle;

    if (newAlbumTitle) {
      // Update albumSelector to show existing album
      albumSelector.value.selectedAlbumId = createdId;
      albumSelector.value.newAlbumTitle = "";

      // Update remaining pending files
      files.value.forEach((f) => {
        if (!f.success && !f.active && f.data) {
          delete f.data["photo[new_album_titles][]"];
          f.data["photo[album_ids][]"] = [createdId];
        }
      });
    }
  }
};

const handleFileInput = function (newFile, oldFile) {
  if (newFile && !oldFile) {
    // add
    console.log("add", newFile);
  }
  if (newFile && oldFile) {
    // update
    console.log("update", newFile);

    // Handle upload success
    if (newFile.success && newFile.response) {
      handleUploadSuccess(newFile, newFile.response);
    }
  }
  if (!newFile && oldFile) {
    // remove
    console.log("remove", oldFile);
  }
};

const startUpload = () => {
  uploadStarted.value = true;
  uploader.value.active = true;
};

const removeUploadedFiles = function () {
  files.value.forEach(function (file) {
    if (file.success) {
      uploader.value.remove(file);
    }
  });

  // Reset upload state if all files are removed
  if (files.value.length === 0) {
    uploadStarted.value = false;
    if (albumSelector.value) {
      albumSelector.value.reset();
    }
  }
};

const removeUploadedFilesDisabled = function () {
  return !files.value.some((file) => file.success);
};

const formatSize = function (size) {
  if (size > 1024 * 1024 * 1024 * 1024) {
    return (size / 1024 / 1024 / 1024 / 1024).toFixed(2) + " TB";
  } else if (size > 1024 * 1024 * 1024) {
    return (size / 1024 / 1024 / 1024).toFixed(2) + " GB";
  } else if (size > 1024 * 1024) {
    return (size / 1024 / 1024).toFixed(2) + " MB";
  } else if (size > 1024) {
    return (size / 1024).toFixed(2) + " KB";
  }
  return size.toString() + " B";
};

const uploadErrorMessage = function (file) {
  if (file.response && file.response.errors) {
    return file.response.errors.join(", ");
  }
  return "Upload failed";
};
</script>
