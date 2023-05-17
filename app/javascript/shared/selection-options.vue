<template>
  <div class="message is-warning">
    <div class="message-header">
      <p>Selection Mode</p>
    </div>
    <div class="message-body">
      <p
        v-if="selectionCount > 0"
      >
        You have selected {{ selectionCount }} photos.
        <router-link
          :to="{
            name: 'photos-selected',
          }"
          class="button is-small"
        >View selected photos.</router-link>
      </p>
      <p
        v-else
      >
        You have not selected any photos.
      </p>
      <p>
        <button
          class="button"
          @click="addAllOnPage()"
        >
          Select All Photos On This Page
        </button>
        <button
          class="button"
          @click="removeAllOnPage()"
        >
          Deselect All Photos On This Page
        </button>
      </p>
      <p>
        <button
          class="button"
          @click="selectionStore.clearPhotos()"
        >
          Clear Selection
        </button>
        <button
          class="button"
          @click="applicationStore.exitSelectionMode()"
        >
          Exit Selection Mode
        </button>
      </p>
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue'

  import { useApplicationStore } from '@/stores/application'
  import { useSelectionStore } from '@/stores/selection';

  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })

  const applicationStore = useApplicationStore()
  const selectionStore = useSelectionStore()

  const selectionCount = computed(() => selectionStore.selectedPhotos.length)

  const addAllOnPage = () => {
    selectionStore.addPhotos(props.photos)
  }

  const removeAllOnPage = () => {
    selectionStore.removePhotos(props.photos)
  }
</script>
