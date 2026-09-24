<template>
  <div class="container">
    <h1 class="title mt-5 mb-0">Upload Photos</h1>
    <hr class="mt-2 mb-4" />

    <div v-show="dropActive" class="drop-active">
      <h3>Drop files here to upload</h3>
    </div>

    <div class="upload-layout">
      <div class="upload-panel">
        <div v-show="!items.length" class="block drop-zone has-text-centered">
          <h4>Drop files anywhere to upload<br />or</h4>
          <button
            type="button"
            class="button is-primary"
            :disabled="uploading"
            @click="openFilePicker"
          >
            <span class="icon is-small">
              <i class="fa fa-plus" aria-hidden="true"></i>
            </span>
            <span>Select Files</span>
          </button>
        </div>

        <template v-if="items.length">
          <div class="upload-summary mb-4">
            <p class="mb-2">{{ summaryText }}</p>
            <progress
              class="progress is-small is-primary"
              :value="overallProgress"
              max="100"
            >
              {{ overallProgress }}%
            </progress>
          </div>

          <PhotoInfobox
            v-if="items.length > 0"
            class="mb-4 upload-batch-box"
            collapsible
            :default-open="false"
          >
            <template #header>
              <SidebarHeader icon="fas fa-tasks" title="Batch Operations" />
            </template>
            <p class="mb-4 upload-batch-help-text">
              Apply a title and/or description to every pending photo at
              once.
            </p>
            <form class="upload-apply-form" @submit.prevent="applyToAllPending">
              <div class="field">
                <label class="label">Title</label>
                <div class="control">
                  <input
                    type="text"
                    class="input"
                    placeholder="Title"
                    aria-label="Title to apply to all pending photos"
                    :disabled="pendingCount === 0"
                    v-model="applyTitle"
                  />
                </div>
              </div>
              <div class="field">
                <label class="label">Description</label>
                <div class="control">
                  <input
                    type="text"
                    class="input"
                    placeholder="Description"
                    aria-label="Description to apply to all pending photos"
                    :disabled="pendingCount === 0"
                    v-model="applyDescription"
                  />
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <button
                    type="submit"
                    class="button is-success"
                    :disabled="pendingCount === 0"
                  >
                    Apply to {{ pendingCount }} pending
                  </button>
                </div>
              </div>
            </form>
          </PhotoInfobox>

          <div class="upload-list mb-4">
            <div class="upload-item" v-for="item in items" :key="item.id">
              <figure class="image upload-thumb">
                <img :src="item.previewUrl" :alt="item.name" />
              </figure>

              <div class="upload-fields">
                <p class="is-size-6 has-text-weak mb-1">
                  {{ item.name }} &middot; {{ formatSize(item.size) }}
                </p>
                <input
                  type="text"
                  class="input mb-1"
                  placeholder="Title"
                  :aria-label="`Title for ${item.name}`"
                  v-model="item.title"
                  :disabled="!editable(item)"
                />
                <textarea
                  class="textarea"
                  rows="2"
                  placeholder="Description (optional)"
                  :aria-label="`Description for ${item.name}`"
                  v-model="item.description"
                  :disabled="!editable(item)"
                >
                </textarea>
                <progress
                  v-if="item.status === 'uploading'"
                  class="progress is-small is-info mt-1"
                  :value="item.progress"
                  max="100"
                >
                  {{ item.progress }}%
                </progress>
                <p
                  v-if="item.status === 'error'"
                  class="has-text-danger is-size-6 mt-1"
                >
                  {{ item.errors.join(", ") || "Upload failed" }}
                </p>
                <p
                  v-if="item.status === 'success' && item.processingTimedOut"
                  class="has-text-weak is-size-6 mt-1"
                >
                  This is taking longer than usual. It'll appear once
                  processing finishes.
                </p>
              </div>

              <div class="upload-status">
                <span
                  :class="[
                    'tag',
                    'is-medium',
                    'upload-status-badge',
                    'mb-2',
                    statusTag(item).tagClass,
                  ]"
                >
                  <span
                    v-if="item.status === 'success' && !item.processed"
                    class="icon"
                  >
                    <i class="fas fa-spinner fa-pulse"></i>
                  </span>
                  {{ statusTag(item).text }}
                </span>
                <div class="upload-status-actions">
                  <button
                    type="button"
                    class="button is-small is-link is-light"
                    v-if="item.status === 'error'"
                    title="Retry"
                    aria-label="Retry upload"
                    @click.prevent="retryItem(item)"
                  >
                    <span class="icon is-small">
                      <i class="fa fa-redo" aria-hidden="true"></i>
                    </span>
                    <span>Retry</span>
                  </button>
                  <button
                    type="button"
                    class="button is-small is-danger is-light"
                    :disabled="item.status === 'uploading'"
                    title="Remove"
                    aria-label="Remove"
                    @click.prevent="remove(item)"
                  >
                    <span class="icon is-small">
                      <i class="fa fa-trash" aria-hidden="true"></i>
                    </span>
                    <span>Remove</span>
                  </button>
                  <router-link
                    v-if="item.status === 'success' && item.slug"
                    class="button is-small is-link is-light is-fullwidth"
                    :to="{ name: 'photos-show', params: { id: item.slug } }"
                  >
                    {{ item.processed ? "View photo" : "Open photo" }}
                  </router-link>
                </div>
              </div>
            </div>
          </div>

          <div
            class="upload-add-more has-text-centered has-text-weak"
            v-if="!uploading"
            role="button"
            tabindex="0"
            @click="openFilePicker"
            @keydown.enter.prevent="openFilePicker"
            @keydown.space.prevent="openFilePicker"
          >
            Drop more photos here or click to add
          </div>
        </template>

        <div class="upload-actions" v-if="items.length">
          <div class="columns is-mobile is-vcentered">
            <div class="column">
              <div class="buttons">
                <button
                  type="button"
                  class="button is-primary"
                  :disabled="uploading"
                  @click="openFilePicker"
                >
                  <span class="icon is-small">
                    <i class="fa fa-plus" aria-hidden="true"></i>
                  </span>
                  <span>Select Files</span>
                </button>
                <button
                  type="button"
                  class="button is-success"
                  v-if="!uploading"
                  :disabled="!hasPending"
                  @click.prevent="uploadAll"
                >
                  <span class="icon is-small">
                    <i class="fa fa-arrow-up" aria-hidden="true"></i>
                  </span>
                  <span>Upload All</span>
                </button>
                <button
                  type="button"
                  class="button is-danger"
                  v-else
                  @click.prevent="stop"
                >
                  <span class="icon is-small">
                    <i class="fa fa-stop" aria-hidden="true"></i>
                  </span>
                  <span>Stop Upload</span>
                </button>
              </div>
            </div>
            <div class="column">
              <div class="buttons is-pulled-right">
                <button
                  type="button"
                  class="button is-danger"
                  :disabled="uploading"
                  @click.prevent="clearAll"
                >
                  <span class="icon is-small">
                    <i class="fa fa-trash" aria-hidden="true"></i>
                  </span>
                  <span>Remove All</span>
                </button>
                <button
                  type="button"
                  class="button is-danger"
                  :disabled="!hasSuccess || uploading"
                  @click.prevent="clearFinished"
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
      </div>

      <aside class="upload-help">
        <PhotoInfobox>
          <template #header>
            <SidebarHeader icon="fas fa-lightbulb" title="Tips" />
          </template>
          <div class="icon-text">
            <span class="icon"><i class="fas fa-file-image"></i></span>
            <span class="has-text-weight-semibold">Accepted files:</span>
            <span class="ml-1">JPG, PNG, GIF and WebP</span>
          </div>
          <div class="icon-text">
            <span class="icon"><i class="fas fa-arrows-alt"></i></span>
            <span class="has-text-weight-semibold">Drag and drop:</span>
            <span class="ml-1"
              >drop more photos anywhere on this page to add them</span
            >
          </div>
          <div class="icon-text">
            <span class="icon"><i class="fas fa-cogs"></i></span>
            <span class="has-text-weight-semibold">Processing:</span>
            <span class="ml-1"
              >thumbnails and tags are generated automatically after upload,
              and the status updates on its own</span
            >
          </div>
          <div class="icon-text">
            <span class="icon"><i class="fas fa-copy"></i></span>
            <span class="has-text-weight-semibold"
              >Same title for several photos?</span
            >
            <span class="ml-1"
              >use "Apply to all pending photos" above instead of retyping
              it</span
            >
          </div>
        </PhotoInfobox>
      </aside>
    </div>

    <input
      ref="fileInput"
      type="file"
      multiple
      accept="image/jpeg,image/png,image/gif,image/webp"
      class="is-hidden"
      @change="onFileInputChange"
    />
  </div>
</template>

<script setup>
import { computed, inject, onMounted, onUnmounted, ref } from "vue";
import { onBeforeRouteLeave } from "vue-router";
import gql from "graphql-tag";
import { useTitle } from "vue-page-title";
import { useUploadQueue } from "../mixins/use-upload-queue.js";
import { useProcessingPoller } from "../mixins/use-processing-poller.js";
import PhotoInfobox from "./photo-infobox.vue";
import SidebarHeader from "./sidebar-header.vue";

useTitle("Upload Photos");

const apolloClient = inject("apolloClient");

async function fetchProcessed(slugs) {
  const { data } = await apolloClient.query({
    query: gql`
      ${gql_queries.photos_processing}
    `,
    variables: { ids: slugs },
    fetchPolicy: "network-only",
  });
  return data.photosByIds.filter((p) => p.processed).map((p) => p.id);
}

const { track, untrack } = useProcessingPoller({
  fetchProcessed,
  onCompleted: () => apolloClient.cache.reset(),
});

const {
  items,
  uploading,
  hasPending,
  hasSuccess,
  add,
  remove,
  clearFinished,
  clearAll,
  start,
  stop,
  retry,
} = useUploadQueue({
  onSuccess: track,
  onRemove: untrack,
});

const fileInput = ref(null);

const openFilePicker = () => fileInput.value.click();

const onFileInputChange = (event) => {
  add(event.target.files);
  event.target.value = "";
};

const editable = (item) => item.status === "pending" || item.status === "error";

const retryItem = (item) => {
  retry(item);
  if (!uploading.value) uploadAll();
};

const uploadAll = () => start();

function statusTag(item) {
  if (item.status === "error") {
    return { tagClass: "is-danger is-light", text: "Failed" };
  }
  if (item.status === "uploading") {
    return { tagClass: "is-info is-light", text: `Uploading ${item.progress}%` };
  }
  if (item.status === "success") {
    if (item.processed) return { tagClass: "is-success is-light", text: "Complete" };
    if (item.processingTimedOut) {
      return { tagClass: "is-warning is-light", text: "Still processing" };
    }
    return { tagClass: "is-warning is-light", text: "Processing" };
  }
  return { tagClass: "is-soft", text: "Ready" };
}

// Batch summary and overall progress, bytes-weighted so a few large files
// don't make the bar look stuck while small ones finish.
const totalSize = computed(() =>
  items.value.reduce((sum, item) => sum + item.size, 0),
);
const successCount = computed(
  () => items.value.filter((item) => item.status === "success").length,
);
const processingCount = computed(
  () =>
    items.value.filter((item) => item.status === "success" && !item.processed)
      .length,
);
const failedCount = computed(
  () => items.value.filter((item) => item.status === "error").length,
);
const pendingCount = computed(
  () => items.value.filter((item) => item.status === "pending").length,
);

const summaryText = computed(() => {
  const parts = [`${successCount.value} of ${items.value.length} uploaded`];
  if (processingCount.value) parts.push(`${processingCount.value} processing`);
  if (failedCount.value) parts.push(`${failedCount.value} failed`);
  parts.push(formatSize(totalSize.value));
  return parts.join(" · ");
});

const overallProgress = computed(() => {
  if (totalSize.value === 0) return 0;
  const uploadedBytes = items.value.reduce((sum, item) => {
    if (item.status === "success") return sum + item.size;
    if (item.status === "uploading") {
      return sum + (item.size * item.progress) / 100;
    }
    return sum;
  }, 0);
  return Math.round((uploadedBytes / totalSize.value) * 100);
});

// Apply a shared title/description to every pending item at once.
const applyTitle = ref("");
const applyDescription = ref("");

const applyToAllPending = () => {
  items.value
    .filter((item) => item.status === "pending")
    .forEach((item) => {
      if (applyTitle.value.trim()) item.title = applyTitle.value;
      if (applyDescription.value.trim()) item.description = applyDescription.value;
    });
};

// Page-wide drop target. A depth counter avoids flicker as the drag crosses
// child elements: enter/leave events fire for every element under the cursor.
const dropActive = ref(false);
let dragDepth = 0;

const isFileDrag = (event) =>
  Array.from(event.dataTransfer?.types ?? []).includes("Files");

const onDragEnter = (event) => {
  if (uploading.value || !isFileDrag(event)) return;
  event.preventDefault();
  dragDepth++;
  dropActive.value = true;
};

const onDragOver = (event) => {
  if (uploading.value || !isFileDrag(event)) return;
  event.preventDefault();
};

const onDragLeave = (event) => {
  if (uploading.value || !isFileDrag(event)) return;
  dragDepth = Math.max(0, dragDepth - 1);
  if (dragDepth === 0) dropActive.value = false;
};

const onDrop = (event) => {
  if (uploading.value || !isFileDrag(event)) return;
  event.preventDefault();
  dragDepth = 0;
  dropActive.value = false;
  add(event.dataTransfer.files);
};

// Warn before leaving with unfinished work: a pending file never got tried,
// an uploading one would be aborted.
const hasUnfinishedWork = () => uploading.value || hasPending.value;
const LEAVE_WARNING =
  "Uploads are still in progress or waiting. Leave anyway?";

const onBeforeUnload = (event) => {
  if (!hasUnfinishedWork()) return;
  event.preventDefault();
  event.returnValue = "";
};

onBeforeRouteLeave(() => {
  if (!hasUnfinishedWork()) return true;
  if (!window.confirm(LEAVE_WARNING)) return false;
  stop();
  return true;
});

onMounted(() => {
  window.addEventListener("dragenter", onDragEnter);
  window.addEventListener("dragover", onDragOver);
  window.addEventListener("dragleave", onDragLeave);
  window.addEventListener("drop", onDrop);
  window.addEventListener("beforeunload", onBeforeUnload);
});

onUnmounted(() => {
  window.removeEventListener("dragenter", onDragEnter);
  window.removeEventListener("dragover", onDragOver);
  window.removeEventListener("dragleave", onDragLeave);
  window.removeEventListener("drop", onDrop);
  window.removeEventListener("beforeunload", onBeforeUnload);
});

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
</script>

<style scoped>
.drop-zone {
  background-color: var(--bulma-scheme-main-bis);
  border: 2px dashed var(--bulma-border);
  border-radius: var(--bulma-radius-large);
  padding: 20px;
  text-align: center;
}

.drop-active {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bulma-scheme-main);
  opacity: 0.95;
  border: 4px dashed var(--bulma-primary);
  pointer-events: none;
}

/* A 2:1 grid spanning the full page width - the working panel, and the Tips
   infobox filling what would otherwise be dead space beside it. */
.upload-layout {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 3rem;
  align-items: start;
}

.upload-panel {
  min-width: 0;
}

/* Margin doesn't shrink a grid gap (siblings are placed by track, not by
   margin collapsing), so sizing the image a few px past its 84px track
   instead - it overflows rightward into the gap, closer to the divider,
   without moving the divider or the fields/status gap on its other side. */
.upload-thumb {
  width: 89px;
  height: 89px;
}

.upload-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: var(--bulma-radius);
}

/* Bulma's .box (card, border, shadow) is kept for the apply-all form below,
   but a plain divided list reads lighter for a list that isn't a form. */
.upload-list {
  border-top: 1px solid var(--bulma-border);
}

.upload-item {
  display: grid;
  grid-template-columns: 84px 1fr 170px;
  column-gap: 1.25rem;
  align-items: start;
  padding: 1rem 0;
  border-bottom: 1px solid var(--bulma-border-weak);
}

.upload-item:last-child {
  border-bottom: none;
}

.upload-fields {
  border-left: 1px solid var(--bulma-border-weak);
  border-right: 1px solid var(--bulma-border-weak);
  padding: 0 1rem;
}

.upload-fields .textarea {
  resize: vertical;
}

.upload-status {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  padding-top: 0.25rem;
}

/* Full-width like the buttons below it, but pill-shaped (not the buttons'
   squarer corners) and non-interactive, so it doesn't read as a button. */
.upload-status-badge {
  width: 100%;
  justify-content: center;
  border-radius: var(--bulma-radius-rounded);
  cursor: default;
}

.upload-status-actions {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 0.375rem;
  width: 100%;
  border-top: 1px solid var(--bulma-border-weak);
  padding-top: 0.5rem;
}

/* Same gap between every field - Title-to-Description and Description-to-
   button - rather than Bulma's stock 1.5rem, which felt loose in this box. */
.upload-apply-form .field:not(:last-child) {
  margin-bottom: 0.75rem;
}

/* :deep() because the header markup itself belongs to PhotoInfobox, not
   this file - only the box's own font-size (0.9rem) applies otherwise. */
.upload-batch-box :deep(.message-header) {
  font-size: 1rem;
}

.upload-batch-help-text {
  font-size: 1rem;
}

.upload-add-more {
  border: 2px dashed var(--bulma-border);
  border-radius: var(--bulma-radius-large);
  padding: 0.75rem;
  margin-bottom: 4.5rem;
  cursor: pointer;
}

/* Solid on purpose: this bar sits over whatever list rows have scrolled
   underneath it, in both themes (--bulma-scheme-main flips with the theme). */
.upload-actions {
  position: sticky;
  bottom: 0;
  z-index: 5;
  background-color: var(--bulma-scheme-main);
  border-top: 1px solid var(--bulma-border);
  padding: 0.75rem 0;
}

.upload-help .icon-text:not(:last-child) {
  margin-bottom: 0.75rem;
}

@media (max-width: 1023px) {
  .upload-layout {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .upload-item {
    grid-template-columns: 84px 1fr;
    grid-template-areas:
      "thumb fields"
      "status status";
    row-gap: 0.5rem;
  }

  .upload-thumb {
    grid-area: thumb;
  }

  .upload-fields {
    grid-area: fields;
  }

  .upload-status {
    grid-area: status;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    text-align: left;
  }
}
</style>
