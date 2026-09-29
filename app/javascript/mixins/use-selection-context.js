import { computed, watch } from "vue";
import { useRoute } from "vue-router";

import { useSelectionStore } from "@/stores/selection";

// Derives the current "selection context" from the route. A context is one
// list (the photo stream, one search, one tag, one album); the page number
// is deliberately excluded so a selection can be gathered across pages of
// the same list.
export function resolveSelectionContext(route) {
  switch (route.name) {
    case "photos-index": {
      const query = route.query.q;
      return {
        type: "photos-index",
        key: query ? `photos-index:q=${query}` : "photos-index",
        param: query || null,
      };
    }
    case "tags-show":
      return { type: "tags-show", key: `tags-show:${route.params.id}`, param: route.params.id };
    case "albums-show":
      return {
        type: "albums-show",
        key: `albums-show:${route.params.id}`,
        param: route.params.id,
      };
    case "photos-search": {
      // Excludes page, like photos-index, so a selection gathers across
      // pages of the same search and resets when the filters change.
      const { page, ...filters } = route.query;
      return {
        type: "photos-search",
        key: `photos-search:${JSON.stringify(filters)}`,
        param: null,
      };
    }
    default:
      return { type: null, key: null, param: null };
  }
}

// Used by list views (to register the context) and by the selection bar (to
// read it). Both derive from the same route-based function, so there's one
// definition of what a context is.
export function useSelectionContext() {
  const route = useRoute();
  const selectionStore = useSelectionStore();

  const context = computed(() => resolveSelectionContext(route));

  watch(
    () => context.value.key,
    (key) => selectionStore.setContext(key),
    { immediate: true },
  );

  return { context };
}
