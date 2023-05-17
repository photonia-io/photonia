<template>
  <div
    v-if="photo.intelligentOrSquareMediumImageUrl"
    class="field checkradio-container"
  >
    <input
      :id="checkbox_id"
      :name="checkbox_name"
      :checked="checkboxChecked()"
      @change="checkboxChanged($event)"
      class="is-checkradio"
      type="checkbox"
    >
    <label
      :for="checkbox_id"
      class="is-checkradio-label">
    </label>
  </div>
</template>

<script setup>
  import { useSelectionStore } from '@/stores/selection'

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    }
  })

  const selectionStore = useSelectionStore()

  const checkbox_id = `photo-checkbox-${props.photo.id}`
  const checkbox_name = `photo-checkbox[${props.photo.id}]`

  const checkboxChanged = (event) => {
    if (event.target.checked) {
      selectionStore.addPhoto(props.photo)
    } else {
      selectionStore.removePhoto(props.photo)
    }
  }

  const checkboxChecked = () => {
    return selectionStore.selectedPhotos.some(photo => photo.id === props.photo.id)
  }
</script>

<style>
  .checkradio-container {
    position: absolute;
    top: 1em;
    right: 0;
    z-index: 1;
  }

  .is-checkradio[type="checkbox"] + label {
    padding-left: 1rem;
  }

  .is-checkradio[type="checkbox"] + label::before {
    background: #fff;
  }
</style>
