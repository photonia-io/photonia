import { computed, onScopeDispose, ref } from "vue";
import { useTokenStore } from "../stores/token.js";

// Files that never belong in an upload batch, regardless of extension.
const SKIP_NAME_PATTERN = /(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/;

const ALLOWED_EXTENSIONS = /\.(jpe?g|png|gif|webp)$/i;
const ALLOWED_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
];

let nextId = 1;

function isAcceptedFile(file) {
  if (SKIP_NAME_PATTERN.test(file.name)) return false;
  if (!ALLOWED_EXTENSIONS.test(file.name)) return false;
  return ALLOWED_MIME_TYPES.includes(file.type);
}

// Sequential upload queue backing photos/upload.vue. Each item carries its own
// form data, so nothing has to be kept in sync across items - the problem
// that made #1010 (album on upload) hard against vue-upload-component.
export function useUploadQueue({
  url = "/photos",
  extraFields,
  onSuccess,
  onRemove,
} = {}) {
  const tokenStore = useTokenStore();

  const items = ref([]);
  const uploading = ref(false);
  let stopRequested = false;
  let activeXhr = null;

  const hasPending = computed(() =>
    items.value.some((item) => item.status === "pending"),
  );
  const hasSuccess = computed(() =>
    items.value.some((item) => item.status === "success"),
  );

  function add(fileList) {
    Array.from(fileList).forEach((file) => {
      if (!isAcceptedFile(file)) return;

      items.value.push({
        id: nextId++,
        file,
        name: file.name,
        size: file.size,
        previewUrl: URL.createObjectURL(file),
        title: file.name,
        description: "",
        status: "pending",
        progress: 0,
        errors: [],
        response: null,
      });
    });
  }

  function revoke(item) {
    URL.revokeObjectURL(item.previewUrl);
    onRemove?.(item);
  }

  function remove(item) {
    if (item.status === "uploading" && activeXhr) {
      activeXhr.abort();
    }
    revoke(item);
    items.value = items.value.filter((i) => i !== item);
  }

  function clearFinished() {
    items.value.filter((item) => item.status === "success").forEach(revoke);
    items.value = items.value.filter((item) => item.status !== "success");
  }

  function clearAll() {
    if (uploading.value && activeXhr) {
      activeXhr.abort();
    }
    items.value.forEach(revoke);
    items.value = [];
  }

  function retry(item) {
    if (item.status !== "error") return;
    item.status = "pending";
    item.progress = 0;
    item.errors = [];
    item.response = null;
  }

  // Used by the Retry button: sends just this one item, rather than going
  // through start()'s loop over every pending item, which would also submit
  // unrelated photos the user hasn't finished editing yet.
  async function retryOne(item) {
    if (item.status !== "error") return;
    retry(item);
    if (uploading.value) return;

    uploading.value = true;
    stopRequested = false;
    await send(item);
    uploading.value = false;
  }

  function buildFormData(item) {
    const formData = new FormData();
    formData.append("photo[title]", item.title);
    formData.append("photo[description]", item.description);
    formData.append("photo[image]", item.file);

    const extra = extraFields?.(item) ?? {};
    Object.entries(extra).forEach(([key, value]) => {
      const values = Array.isArray(value) ? value : [value];
      values.forEach((v) => formData.append(key, v));
    });

    return formData;
  }

  // XMLHttpRequest, not fetch: fetch has no upload progress events.
  function send(item) {
    return new Promise((resolve) => {
      const xhr = new XMLHttpRequest();
      activeXhr = xhr;

      xhr.open("POST", url);
      xhr.setRequestHeader("Accept", "application/json");
      if (tokenStore.authorization) {
        xhr.setRequestHeader("Authorization", tokenStore.authorization);
      }

      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          item.progress = Math.round((event.loaded / event.total) * 100);
        }
      };

      xhr.onload = () => {
        activeXhr = null;
        let body = null;
        try {
          body = xhr.responseText ? JSON.parse(xhr.responseText) : null;
        } catch {
          body = null;
        }

        if (xhr.status >= 200 && xhr.status < 300 && body) {
          item.status = "success";
          item.progress = 100;
          item.response = body;
          onSuccess?.(item);
        } else {
          item.status = "error";
          item.errors = body?.errors ?? [
            `Upload failed (HTTP ${xhr.status})`,
          ];
        }
        resolve();
      };

      xhr.onerror = () => {
        activeXhr = null;
        item.status = "error";
        item.errors = ["Network error"];
        resolve();
      };

      xhr.onabort = () => {
        activeXhr = null;
        resolve();
      };

      item.status = "uploading";
      item.progress = 0;
      xhr.send(buildFormData(item));
    });
  }

  // One request at a time, on purpose: album creation and Apollo cache
  // resets downstream assume a batch completes strictly in order.
  async function start() {
    if (uploading.value) return 0;

    uploading.value = true;
    stopRequested = false;
    let successCount = 0;

    let next = items.value.find((item) => item.status === "pending");
    while (next && !stopRequested) {
      await send(next);
      if (next.status === "success") successCount++;
      next = items.value.find((item) => item.status === "pending");
    }

    uploading.value = false;
    return successCount;
  }

  function stop() {
    stopRequested = true;
    if (activeXhr) {
      activeXhr.abort();
    }
    const current = items.value.find((item) => item.status === "uploading");
    if (current) {
      current.status = "pending";
      current.progress = 0;
    }
  }

  onScopeDispose(() => {
    if (activeXhr) activeXhr.abort();
    items.value.forEach(revoke);
  });

  return {
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
    retryOne,
  };
}
