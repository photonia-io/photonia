import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

import { useUserStore } from "@/stores/user";

// Selection is scoped to one "context" at a time (one photo list: the photo
// stream, a search, a tag, an album). Actions never act across contexts.
// Up to MAX_CONTEXTS are remembered so leaving a context and coming back
// restores what was selected there.
const MAX_CONTEXTS = 3;
const STORAGE_PREFIX = "selection:";

function emptyData() {
  return { version: 1, contexts: {} };
}

function loadFromStorage(key) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return emptyData();
    const parsed = JSON.parse(raw);
    return parsed && parsed.contexts ? parsed : emptyData();
  } catch {
    // Private browsing, corrupted JSON, etc. Fall back to an empty selection
    // rather than throwing.
    return emptyData();
  }
}

function saveToStorage(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch {
    // Quota exceeded or storage unavailable. The selection still works for
    // the rest of the session, it just won't survive a reload.
  }
}

// Only { id, title, thumbnailUrl } are kept, not the whole list-query object,
// so a stored selection never goes stale and doesn't grow with whatever
// fields a particular list query happens to request.
function slim(photo) {
  return {
    id: photo.id,
    title: photo.title,
    thumbnailUrl: photo.intelligentOrSquareMediumImageUrl || photo.thumbnailUrl || null,
  };
}

export const useSelectionStore = defineStore("selection", () => {
  const userStore = useUserStore();

  // Namespaced per user so signing out (or in as someone else on the same
  // browser) never shows or inherits another account's selection.
  const storageKey = computed(() =>
    userStore.email ? `${STORAGE_PREFIX}${userStore.email}` : null,
  );

  const data = ref(emptyData());

  watch(
    storageKey,
    (key) => {
      data.value = key ? loadFromStorage(key) : emptyData();
    },
    { immediate: true },
  );

  watch(
    data,
    (newValue) => {
      if (storageKey.value) saveToStorage(storageKey.value, newValue);
    },
    { deep: true },
  );

  // The active context key (set by useSelectionContext as routes change),
  // the current list view's page of photos (for select/deselect-all and
  // shift-click ranges), and a touch-only hint that reveals checkboxes with
  // nothing selected yet, so long-press is discoverable.
  const activeContextKey = ref(null);
  const pageCollection = ref([]);
  const lastToggledId = ref(null);
  const selectingHint = ref(false);

  function setContext(key) {
    if (key === activeContextKey.value) return;
    activeContextKey.value = key;
    lastToggledId.value = null;
  }

  function setPageCollection(photos) {
    pageCollection.value = photos || [];
  }

  function setSelectingHint(value) {
    selectingHint.value = value;
  }

  function touchContext(key) {
    if (!data.value.contexts[key]) {
      data.value.contexts[key] = { photos: [], touchedAt: Date.now() };
    } else {
      data.value.contexts[key].touchedAt = Date.now();
    }
    evictOldContexts();
  }

  function evictOldContexts() {
    const keys = Object.keys(data.value.contexts);
    if (keys.length <= MAX_CONTEXTS) return;
    const oldestFirst = keys.sort(
      (a, b) => data.value.contexts[a].touchedAt - data.value.contexts[b].touchedAt,
    );
    for (const key of oldestFirst.slice(0, keys.length - MAX_CONTEXTS)) {
      delete data.value.contexts[key];
    }
  }

  const selected = computed(() => {
    if (!activeContextKey.value) return [];
    return data.value.contexts[activeContextKey.value]?.photos || [];
  });

  const count = computed(() => selected.value.length);

  const isSelecting = computed(() => count.value > 0 || selectingHint.value);

  function isSelected(id) {
    return selected.value.some((photo) => photo.id === id);
  }

  function add(photo) {
    if (!activeContextKey.value) return;
    touchContext(activeContextKey.value);
    const list = data.value.contexts[activeContextKey.value].photos;
    if (!list.find((p) => p.id === photo.id)) list.push(slim(photo));
    lastToggledId.value = photo.id;
  }

  function remove(photoOrId) {
    if (!activeContextKey.value) return;
    const id = typeof photoOrId === "string" ? photoOrId : photoOrId.id;
    touchContext(activeContextKey.value);
    const ctx = data.value.contexts[activeContextKey.value];
    ctx.photos = ctx.photos.filter((p) => p.id !== id);
    lastToggledId.value = id;
  }

  function toggle(photo) {
    if (isSelected(photo.id)) {
      remove(photo);
    } else {
      add(photo);
    }
  }

  function addMany(photos) {
    if (!activeContextKey.value || !photos || photos.length === 0) return;
    touchContext(activeContextKey.value);
    const ctx = data.value.contexts[activeContextKey.value];
    for (const photo of photos) {
      if (!ctx.photos.find((p) => p.id === photo.id)) ctx.photos.push(slim(photo));
    }
  }

  function removeMany(photosOrIds) {
    if (!activeContextKey.value || !photosOrIds || photosOrIds.length === 0) return;
    const ids = new Set(photosOrIds.map((p) => (typeof p === "string" ? p : p.id)));
    touchContext(activeContextKey.value);
    const ctx = data.value.contexts[activeContextKey.value];
    ctx.photos = ctx.photos.filter((p) => !ids.has(p.id));
  }

  // Selects everything between the last toggled photo and `toId`, inclusive,
  // within the current page's collection. Falls back to a plain toggle when
  // there's nothing to range from (first click, or the anchor scrolled off
  // via pagination).
  function selectRange(toId) {
    const ids = pageCollection.value.map((p) => p.id);
    const fromIndex = lastToggledId.value ? ids.indexOf(lastToggledId.value) : -1;
    const toIndex = ids.indexOf(toId);

    if (fromIndex === -1 || toIndex === -1) {
      const photo = pageCollection.value.find((p) => p.id === toId);
      if (photo) toggle(photo);
      return;
    }

    const [start, end] = fromIndex < toIndex ? [fromIndex, toIndex] : [toIndex, fromIndex];
    addMany(pageCollection.value.slice(start, end + 1));
    lastToggledId.value = toId;
  }

  function clear() {
    if (!activeContextKey.value) return;
    const ctx = data.value.contexts[activeContextKey.value];
    if (ctx) ctx.photos = [];
  }

  // Drops specific photos from the current context (e.g. after they're
  // deleted) without discarding the rest of the selection.
  function prune(ids) {
    if (!activeContextKey.value || !ids || ids.length === 0) return;
    const idSet = new Set(ids);
    const ctx = data.value.contexts[activeContextKey.value];
    if (ctx) ctx.photos = ctx.photos.filter((p) => !idSet.has(p.id));
  }

  function clearAll() {
    data.value = emptyData();
  }

  return {
    activeContextKey,
    pageCollection,
    selectingHint,
    selected,
    count,
    isSelecting,
    isSelected,
    setContext,
    setPageCollection,
    setSelectingHint,
    add,
    remove,
    toggle,
    addMany,
    removeMany,
    selectRange,
    clear,
    prune,
    clearAll,
  };
});
