<template>
  <div
    id="image-wrapper"
    :style="'background: no-repeat url(' + photo.largeImageUrl + ') 50% / 100%'"
  >
    <img :src="photo.largeImageUrl" />
    <div
      v-if="photo.labels"
      class="labels"
    >
      <DisplayLabel
        v-for="label in photo.labels"
        :label="label"
        :highlighted="labelHighlights[label.id]"
        :key="label.id"
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
  import DisplayLabel from './display-label.vue'

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
