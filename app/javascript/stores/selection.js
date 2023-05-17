import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export const useSelectionStore = defineStore('selection', () => {
  const selectedPhotos = ref(JSON.parse(localStorage.getItem('selectedPhotos') || '[]'))

  watch(
    selectedPhotos, (newValue) => {
      localStorage.setItem('selectedPhotos', JSON.stringify(newValue))
    },
    { deep: true }
  )

  const addPhoto = (photo) => {
    if (!selectedPhotos.value.find((item) => item.id === photo.id)) {
      selectedPhotos.value.push(photo)
    }
  }

  const removePhoto = (photo) => {
    selectedPhotos.value = selectedPhotos.value.filter((item) => item.id !== photo.id)
  }

  const clearPhotos = () => {
    selectedPhotos.value = new Array()
  }

  const addPhotos = (photos) => {
    let newSelectedPhotos = selectedPhotos.value
    photos.forEach((photo) => {
      if (!newSelectedPhotos.find((item) => item.id === photo.id)) {
        newSelectedPhotos.push(photo)
      }
    })
    selectedPhotos.value = newSelectedPhotos
  }

  const removePhotos = (photos) => {
    selectedPhotos.value = selectedPhotos.value.filter((item) => !photos.find((photo) => photo.id === item.id))
  }

  return { selectedPhotos, addPhoto, removePhoto, clearPhotos, addPhotos, removePhotos }
})
