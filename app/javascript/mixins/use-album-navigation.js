import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";

// J/K are ordinary letters, so a shortcut must never fire while the user is
// typing. Applies to the arrow keys too, which had no such guard.
export function isTypingTarget(target) {
  return (
    target?.isContentEditable ||
    ["INPUT", "TEXTAREA", "SELECT"].includes(target?.tagName)
  );
}

// Album navigation state lives entirely in the ?inAlbum= query param, so back,
// forward, reload and shared links all behave. `photo` is the ref holding the
// currently displayed photo.
export function useAlbumNavigation(photo) {
  const route = useRoute();
  const router = useRouter();

  const inAlbumId = computed(() => route.query.inAlbum || null);

  // Null while inAlbumId is set means dormant: we navigated out of the album,
  // so the keys do nothing until we come back to a photo that is in it.
  const navigatingAlbum = computed(
    () =>
      photo.value.albums?.find((album) => album.id === inAlbumId.value) ?? null,
  );

  // Carried through every photos-show navigation so the mode can resume.
  const navigationQuery = computed(() =>
    inAlbumId.value ? { inAlbum: inAlbumId.value } : {},
  );

  const navigateToPhoto = (target) => {
    if (!target) return;

    router.push({
      name: "photos-show",
      params: { id: target.id },
      query: navigationQuery.value,
    });
  };

  const albumRoute = (album) => ({
    name: "albums-show",
    params: { id: album.id },
    query:
      album.photoPositionInAlbum?.page > 1
        ? { page: album.photoPositionInAlbum.page }
        : {},
  });

  const startNavigatingAlbum = (albumId) => {
    router.push({
      name: "photos-show",
      params: { id: route.params.id },
      query: { inAlbum: albumId },
    });
  };

  const stopNavigatingAlbum = () => {
    router.push({ name: "photos-show", params: { id: route.params.id } });
  };

  const navigateToNextPhotoInAlbum = () =>
    navigateToPhoto(navigatingAlbum.value?.nextPhotoInAlbum);

  const navigateToPreviousPhotoInAlbum = () =>
    navigateToPhoto(navigatingAlbum.value?.previousPhotoInAlbum);

  return {
    inAlbumId,
    navigatingAlbum,
    navigationQuery,
    navigateToPhoto,
    albumRoute,
    startNavigatingAlbum,
    stopNavigatingAlbum,
    navigateToNextPhotoInAlbum,
    navigateToPreviousPhotoInAlbum,
  };
}
