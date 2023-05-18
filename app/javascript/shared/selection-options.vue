<template>
  <div class="message is-warning">
    <div class="message-body content">
      <p
        v-if="selectionCount > 0"
      >
        You have selected <strong>{{ selectionCount }}</strong> photos.
      </p>
      <p
        v-else
      >
        You have not selected any photos.
      </p>
      <div class="level">
        <div class="level-left">
          <div class="buttons">
            <router-link
              :to="buttonsDisabled ? {} : { name: 'photos-organizer' }"
              :disabled="buttonsDisabled ? 'disabled' : null"
              class="button is-primary"
            >
              Go to the Organizer
            </router-link>
            <button
              class="button is-danger"
              :disabled="buttonsDisabled"
              @click="selectionStore.clearPhotos()"
            >
              <span class="icon">
                <i class="fas fa-times"></i>
              </span>
              <span>Clear Selection</span>
            </button>
          </div>
        </div>
        <div class="level-right">
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
        </div>
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
  const buttonsDisabled = computed(() => selectionCount.value === 0)

  const addAllOnPage = () => {
    selectionStore.addPhotos(props.photos)
  }

  const removeAllOnPage = () => {
    selectionStore.removePhotos(props.photos)
  }
</script>
