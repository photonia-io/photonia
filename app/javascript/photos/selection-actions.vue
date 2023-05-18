<template>
  <div class="message is-warning">
    <div class="message-body content">
      <p>
        If you accidentally removed a photo from the Organizer, and want to add it back to the selection, please click here.
      </p>
      <p>
        If you want to remove a photo from the selection, please click on the photo.
      </p>
      <p>
        The actions below will be applied to all selected photos.
      </p>
    </div>
  </div>
</template>

<script setup>
  import { useSelectionStore } from '@/stores/selection'

  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })

  const selectionStore = useSelectionStore()
</script>
