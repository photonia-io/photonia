import { defineStore } from "pinia";
import { ref, watch } from "vue";

export const useSelectionStore = defineStore("selection", () => {
  // selectedPhotos / deselectedPhotos refers to the photos selected from the photo stream / search results

  const selectedPhotos = ref(
    JSON.parse(localStorage.getItem("selectedPhotos") || "[]"),
  );
  const deselectedPhotos = ref(
    JSON.parse(localStorage.getItem("deselectedPhotos") || "[]"),
  );
  const showRemoveNotification = ref(true);

  watch(
    selectedPhotos,
    (newValue) => {
      localStorage.setItem("selectedPhotos", JSON.stringify(newValue));
    },
    { deep: true },
  );

  watch(
    deselectedPhotos,
    (newValue) => {
      localStorage.setItem("deselectedPhotos", JSON.stringify(newValue));
    },
    { deep: true },
  );

  const addPhoto = (photo) => {
    // add to selectedPhotos if not already there
    if (!selectedPhotos.value.find((item) => item.id === photo.id)) {
      selectedPhotos.value.push(photo);
    }
    // remove from deselectedPhotos if there
    deselectedPhotos.value = deselectedPhotos.value.filter(
      (item) => item.id !== photo.id,
    );
  };

  const removePhoto = (photo) => {
    // remove from selectedPhotos if there
    selectedPhotos.value = selectedPhotos.value.filter(
      (item) => item.id !== photo.id,
    );
    // add to deselectedPhotos if not already there
    if (!deselectedPhotos.value.find((item) => item.id === photo.id)) {
      deselectedPhotos.value.push(photo);
    }
  };

  const clearSelectedPhotos = () => {
    selectedPhotos.value = new Array();
  };

  const clearDeselectedPhotos = () => {
    deselectedPhotos.value = new Array();
  };

  const clearPhotoSelection = () => {
    clearSelectedPhotos();
    clearDeselectedPhotos();
  };

  const addPhotos = (photos) => {
    let newSelectedPhotos = selectedPhotos.value;
    photos.forEach((photo) => {
      if (!newSelectedPhotos.find((item) => item.id === photo.id)) {
        newSelectedPhotos.push(photo);
      }
    });
    selectedPhotos.value = newSelectedPhotos;
  };

  const removePhotos = (photos) => {
    selectedPhotos.value = selectedPhotos.value.filter(
      (item) => !photos.find((photo) => photo.id === item.id),
    );
  };

  // --- selectedAlbumPhotos refers to the photos selected when editing an album ---

  const selectedAlbumPhotos = ref(new Array());

  const addAlbumPhoto = (photo) => {
    // add to selectedAlbumPhotos if not already there
    if (!selectedAlbumPhotos.value.find((item) => item.id === photo.id)) {
      selectedAlbumPhotos.value.push(photo);
    }
  };

  const removeAlbumPhoto = (photo) => {
    // remove from selectedAlbumPhotos if there
    selectedAlbumPhotos.value = selectedAlbumPhotos.value.filter(
      (item) => item.id !== photo.id,
    );
  };

  const clearSelectedAlbumPhotos = () => {
    selectedAlbumPhotos.value = new Array();
  };

  const addAlbumPhotos = (photos) => {
    let newSelectedPhotos = selectedAlbumPhotos.value;
    photos.forEach((photo) => {
      if (!newSelectedPhotos.find((item) => item.id === photo.id)) {
        newSelectedPhotos.push(photo);
      }
    });
    selectedAlbumPhotos.value = newSelectedPhotos;
  };

  const removeAlbumPhotos = (photos) => {
    selectedAlbumPhotos.value = selectedAlbumPhotos.value.filter(
      (item) => !photos.find((photo) => photo.id === item.id),
    );
  };

  return {
    selectedPhotos,
    deselectedPhotos,
    showRemoveNotification,
    addPhoto,
    removePhoto,
    clearSelectedPhotos,
    clearDeselectedPhotos,
    clearPhotoSelection,
    addPhotos,
    removePhotos,
    selectedAlbumPhotos,
    addAlbumPhoto,
    removeAlbumPhoto,
    clearSelectedAlbumPhotos,
    addAlbumPhotos,
    removeAlbumPhotos,
  };
});
