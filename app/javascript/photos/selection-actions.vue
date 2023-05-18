<template>
  <div class="message is-warning">
    <div class="message-body content">
      <p>
        If you accidentally removed a photo from the selection, and want to add it back, please <router-link :to="{ name: 'photos-deselected' }">see the list of recently deselected photos</router-link>.
      </p>
      <p
        v-if="selectionCount > 1"
      >
        The actions below will be applied to <strong>all of the following {{ selectionCount }} photos</strong>.
      </p>
      <p
        v-else-if="selectionCount === 1"
      >
        The actions below will be applied to <strong>the following photo</strong>.
      </p>
      <p
        v-else-if="selectionCount === 0"
      >
        You have not selected any photos.
      </p>
      <div class="buttons">
        <button
          class="button"
          :disabled="buttonsDisabled"
          @click="addToAlbum()"
        >
          <span class="icon-text">
            <span class="icon"><i class="fas fa-folder-plus"></i></span>
            <span>Add To Album</span>
          </span>
        </button>
        <button
          class="button"
          :disabled="buttonsDisabled"
          @click="addTags()"
        >
          <span class="icon-text">
            <span class="icon"><i class="fas fa-tag"></i></span>
            <span>Add Tags</span>
          </span>
        </button>
        <button
          class="button is-danger"
          :disabled="buttonsDisabled"
          @click="deletePhotos()"
        >
          <span class="icon-text">
            <span class="icon"><i class="fas fa-trash"></i></span>
            <span>Delete</span>
          </span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue'
  import { useSelectionStore } from '@/stores/selection'

  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })

  const selectionStore = useSelectionStore()

  const selectionCount = computed(() => selectionStore.selectedPhotos.length)
  const buttonsDisabled = computed(() => selectionCount.value === 0)
</script>
