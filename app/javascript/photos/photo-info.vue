<template>
  <PhotoInfobox>
    <template #header>
      <SidebarHeader icon="fas fa-info-circle" title="Info" />
    </template>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-eye"></i></span>
      <span class="has-text-weight-semibold">Views:</span>
      <span v-if="!loading" class="ml-1">{{ photo.impressionsCount }}</span>
    </div>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-camera"></i></span>
      <span class="has-text-weight-semibold">Date Taken:</span>
      <span v-if="!loading" class="ml-1">{{
        momentFormat(photo.takenAt)
      }}</span>
      <span
        v-if="!loading && photo.isTakenAtFromExif"
        class="tag has-background ml-1 has-text-weight-bold"
      >
        EXIF
      </span>
    </div>
    <div class="icon-text">
      <span class="icon"><i class="fas fa-arrow-circle-up"></i></span>
      <span class="has-text-weight-semibold">Date Posted:</span>
      <span v-if="!loading" class="ml-1">{{
        momentFormat(photo.postedAt)
      }}</span>
    </div>
    <div
      v-if="!loading && photo.rekognitionLabelModelVersion !== ''"
      class="icon-text"
    >
      <span class="icon"><i class="fas fa-robot"></i></span>
      <span class="has-text-weight-semibold"
        >Rekognition Label Model Version:</span
      >
      <span class="ml-1">{{ photo.rekognitionLabelModelVersion }}</span>
    </div>
  </PhotoInfobox>
</template>

<script setup>
import PhotoInfobox from "./photo-infobox.vue";
import SidebarHeader from "./sidebar-header.vue";
import moment from "moment/min/moment-with-locales";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    required: true,
  },
});

const format = "dddd, MMMM Do YYYY, H:mm";
function momentFormat(date) {
  return moment(date).format(format);
}
</script>
