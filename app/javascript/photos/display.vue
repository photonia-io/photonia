<template>
  <div
    id="image-wrapper"
    :style="'background: no-repeat url(' + photo.largeImageUrl + ') 50% / 100%'"
  >
    <img :src="photo.largeImageUrl" />
    <div
      v-if="photo.labelInstances"
      class="labels"
    >
      <DisplayLabelInstance
        v-for="labelInstance in photo.labelInstances"
        :labelInstance="labelInstance"
        :highlighted="labelHighlights[labelInstance.id]"
        :key="labelInstance.id"
      />
      <div v-if="photo.intelligentThumbnail">
        <div :style="' \
          border: 3px solid red; \
          position: absolute; \
          top: ' + photo.intelligentThumbnail.centerOfGravity.top * 100 + '%; \
          left: ' + photo.intelligentThumbnail.centerOfGravity.left * 100 + '%; \
          width: 2px; \
          height: 2px; \
          opacity: 0'
        "/>
        <div :style="' \
          border: 1px solid blue; \
          position: absolute; \
          top: ' + photo.intelligentThumbnail.boundingBox.top * 100 + '%; \
          left: ' + photo.intelligentThumbnail.boundingBox.left * 100 + '%; \
          width: ' + photo.intelligentThumbnail.boundingBox.width * 100 + '%; \
          height: ' + photo.intelligentThumbnail.boundingBox.height * 100 + '%; \
          opacity: 0'
        "/>
      </div>
    </div>
  </div>
</template>

<script setup>
  import DisplayLabelInstance from './display-label-instance.vue'

  const props = defineProps({
    photo: {
      type: Object,
      required: true
    },
    labelHighlights: {
      type: Object,
      required: false
    }
  })
</script>

<style scoped>
  #image-wrapper {
    position: relative;
  }
  #image-wrapper > img {
    vertical-align: top;
    width: 100%;
    opacity: 0;
  }
  #image-wrapper > .labels {
    position: absolute;
    top: 0;
    width: 100%;
    height: 100%;
  }
</style>
