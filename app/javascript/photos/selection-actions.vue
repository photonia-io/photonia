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
        <AddToAlbumButton
          :photos="props.photos"
        />
        <AddTagsButton
          :photos="props.photos"
        />
        <DeleteButton
          :photos="props.photos"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue'
  import { useSelectionStore } from '@/stores/selection'

  import AddToAlbumButton from '@/shared/buttons/add-to-album.vue'
  import AddTagsButton from '@/shared/buttons/add-tags.vue'
  import DeleteButton from '@/shared/buttons/delete.vue'

  const props = defineProps({
    photos: {
      type: Array,
      required: true
    }
  })

  const selectionStore = useSelectionStore()

  const selectionCount = computed(() => selectionStore.selectedPhotos.length)
</script>
