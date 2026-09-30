import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useApplicationStore } from "@/stores/application";

export const LIGHTBOX_PARAM = "lightbox";

// True when `to` and `from` are the same page differing only by the
// lightbox param, so the "are you sure you want to navigate away" editing
// guard (router/index.js) can let it through without prompting.
export function onlyLightboxToggled(to, from) {
  if (to.path !== from.path) return false;

  const withoutLightbox = (query) => {
    const { [LIGHTBOX_PARAM]: _omit, ...rest } = query;
    return rest;
  };

  const toRest = withoutLightbox(to.query);
  const fromRest = withoutLightbox(from.query);
  const keys = new Set([...Object.keys(toRest), ...Object.keys(fromRest)]);
  for (const key of keys) {
    if (toRest[key] !== fromRest[key]) return false;
  }
  return true;
}

// Keeps the lightbox reflected in the ?lightbox= query param: back closes it
// (the natural Android gesture for dismissing a fullscreen view), and a
// copied URL reopens straight into it.
export function useLightboxRoute() {
  const route = useRoute();
  const router = useRouter();
  const applicationStore = useApplicationStore();

  const lightboxRequested = computed(() => LIGHTBOX_PARAM in route.query);

  // Opening in-app (a click, or a step - see stepInLightbox): pushed, so
  // closing can undo it cleanly with router.back().
  const openLightboxRoute = () => {
    applicationStore.lightboxOpenedByPush = true;
    router.push({
      path: route.path,
      query: { ...route.query, [LIGHTBOX_PARAM]: "1" },
    });
  };

  // The param was already on the URL when this component saw it (a direct
  // load or the forward button) - there's nothing of ours to go back to.
  const acknowledgeLightboxFromUrl = () => {
    applicationStore.lightboxOpenedByPush = false;
  };

  // Drops the param. Back when the app pushed the entry that carries it
  // (undoes that push cleanly); replace otherwise, so closing a lightbox
  // opened from a shared link stays on the photo rather than leaving
  // whatever page - or site - came before it.
  const leaveLightboxRoute = () => {
    const { [LIGHTBOX_PARAM]: _omit, ...query } = route.query;
    if (applicationStore.lightboxOpenedByPush) {
      router.back();
    } else {
      router.replace({ path: route.path, query });
    }
  };

  // A next/prev step while the lightbox is open. Swaps the current entry
  // for the new photo, then pushes its own ?lightbox entry: opening on A and
  // stepping to B turns "A, A?lightbox" into "A, B, B?lightbox" - a later
  // close still lands on B rather than back at A.
  const stepInLightbox = async (location) => {
    applicationStore.lightboxStepping = true;
    try {
      await router.replace(location);
      applicationStore.lightboxOpenedByPush = true;
      await router.push({
        ...location,
        query: { ...location.query, [LIGHTBOX_PARAM]: "1" },
      });
    } finally {
      applicationStore.lightboxStepping = false;
    }
  };

  return {
    lightboxRequested,
    openLightboxRoute,
    acknowledgeLightboxFromUrl,
    leaveLightboxRoute,
    stepInLightbox,
  };
}
