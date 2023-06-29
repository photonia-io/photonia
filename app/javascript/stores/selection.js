import { defineStore } from "pinia";
import { ref, watch } from "vue";

export const useSelectionStore = defineStore("selection", () => {
  const selectedPhotos = ref(
    JSON.parse(localStorage.getItem("selectedPhotos") || "[]")
  );
  const deselectedPhotos = ref(
    JSON.parse(localStorage.getItem("deselectedPhotos") || "[]")
  );
  const showRemoveNotification = ref(true);

  watch(
    selectedPhotos,
    (newValue) => {
      localStorage.setItem("selectedPhotos", JSON.stringify(newValue));
    },
    { deep: true }
  );

  watch(
    deselectedPhotos,
    (newValue) => {
      localStorage.setItem("deselectedPhotos", JSON.stringify(newValue));
    },
    { deep: true }
  );

  const addPhoto = (photo) => {
    // add to selectedPhotos if not already there
    if (!selectedPhotos.value.find((item) => item.id === photo.id)) {
      selectedPhotos.value.push(photo);
    }
    // remove from deselectedPhotos if there
    deselectedPhotos.value = deselectedPhotos.value.filter(
      (item) => item.id !== photo.id
    );
  };

  const removePhoto = (photo) => {
    // remove from selectedPhotos if there
    selectedPhotos.value = selectedPhotos.value.filter(
      (item) => item.id !== photo.id
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
      (item) => !photos.find((photo) => photo.id === item.id)
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
  };
});
