<template>
  <div class="column is-one-quarter is-relative">
    <router-link :to="{ name: 'photos-show', params: { id: photo.id } }">
      <img
        v-if="photo.intelligentOrSquareMediumImageUrl"
        :src="photo.intelligentOrSquareMediumImageUrl"
        class="image is-fullwidth"
      />
      <ImagePlaceholder
        v-else
      />
      {{ photo.name }}
    </router-link>
    <SelectionCheckbox
      v-if="userStore.signedIn && applicationStore.selectionMode"
      :photo="photo"
    />
  </div>
</template>

<script setup>
  import { useUserStore } from '@/stores/user'
  import { useApplicationStore } from '@/stores/application';

  import ImagePlaceholder from '@/shared/image-placeholder.vue'
  import SelectionCheckbox from '@/shared/selection-checkbox.vue'

  const userStore = useUserStore()
  const applicationStore = useApplicationStore()

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    }
  })
</script>
