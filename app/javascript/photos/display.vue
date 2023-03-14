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
      <LabelInstance
        v-for="labelInstance in photo.labelInstances"
        :labelInstance="labelInstance"
        :key="labelInstance.id"
      />
      <div v-if="photo.intelligentThumbnail">
        <div :style="' \
          border: 3px solid red; \
          position: absolute; \
          top: ' + photo.intelligentThumbnail.centerOfGravityTop * 100 + '%; \
          left: ' + photo.intelligentThumbnail.centerOfGravityLeft * 100 + '%; \
          width: 2px; \
          height: 2px;'
        "/>
        <div :style="' \
          border: 1px solid blue; \
          position: absolute; \
          top: ' + photo.intelligentThumbnail.boundingBox.top * 100 + '%; \
          left: ' + photo.intelligentThumbnail.boundingBox.left * 100 + '%; \
          width: ' + photo.intelligentThumbnail.boundingBox.width * 100 + '%; \
          height: ' + photo.intelligentThumbnail.boundingBox.height * 100 + '%;'
        "/>
      </div>
    </div>
  </div>
</template>

<script>
import LabelInstance from './label-instance.vue'

export default {
  props: [ 'photo' ],
  components: {
    LabelInstance
  }
}
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
    opacity: 0;
    transition: 0.3s;
  }
  #image-wrapper:hover > .labels {
    opacity: 1;
  }
  .label {
    cursor: pointer;
    border: 2px dotted green; position: absolute;
    transition: 0.3s;
  }
  .label:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }
</style>
