<template>
  <div class="message is-warning">
    <div class="message-header">
      <p>Selection Mode</p>
    </div>
    <div class="message-body content">
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
      <div class="buttons">
        <button
          class="button"
          @click="addAllOnPage()"
        >
          <span class="icon-text">
            <span class="icon"><i class="far fa-check-square"></i></span>
            <span>Select All Photos On This Page</span>
          </span>
        </button>
        <button
          class="button"
          @click="removeAllOnPage()"
        >
          <span class="icon-text">
            <span class="icon"><i class="far fa-square"></i></span>
            <span>Deselect All Photos On This Page</span>
          </span>
        </button>
      </div>
      <div class="buttons">
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
          <span class="icon-text">
            <span class="icon"><i class="fas fa-sign-out-alt"></i></span>
            <span>Exit Selection Mode</span>
          </span>
        </button>
      </div>
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
