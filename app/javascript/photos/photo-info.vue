<template>
  <SidebarHeader
    icon="fas fa-info-circle"
    title="Info"
  />
  <div class="block">
    <span class="icon-text is-size-7">
      <!-- display views -->
      <span class="icon"><i class="fas fa-eye"></i></span>
      <span class="has-text-weight-semibold">Views:</span>
      <span v-if="!loading" class="ml-1">{{ photo.impressions }}</span>
    </span>
    <span class="icon-text is-size-7">
      <span class="icon"><i class="fas fa-camera"></i></span>
      <span class="has-text-weight-semibold">Date Taken:</span>
      <span v-if="!loading" class="ml-1">{{ momentFormat(photo.dateTaken) }}</span>
    </span>
    <span class="icon-text is-size-7">
      <span class="icon"><i class="fas fa-arrow-circle-up"></i></span>
      <span class="has-text-weight-semibold">Date Posted:</span>
      <span v-if="!loading" class="ml-1">{{ momentFormat(photo.importedAt) }}</span>
    </span>
    <span
      v-if="!loading && photo.rekognitionLabelModelVersion !== ''"
      class="icon-text is-size-7"
    >
      <span class="icon"><i class="fas fa-robot"></i></span>
      <span class="has-text-weight-semibold">Rekognition Label Model Version:</span>
      <span class="ml-1">{{ photo.rekognitionLabelModelVersion }}</span>
    </span>
  </div>
</template>

<script setup>
  import SidebarHeader from './sidebar-header.vue'
  import moment from 'moment/min/moment-with-locales'

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    },
    loading: {
      type: Boolean,
      required: true
    }
  })

  const format = 'dddd, MMMM Do YYYY, H:mm'
  function momentFormat(date) {
    return moment(date).format(format)
  }
</script>