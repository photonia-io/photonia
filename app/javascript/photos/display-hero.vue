<template>
  <div class="hero is-dark mb-4">
    <div class="hero-body pt-5 pb-4" style="text-align: center;">
      <div id="image-wrapper">
        <img :src="photo.extralargeImageUrl" />
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
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { computed, ref, onMounted, onUnmounted } from 'vue'
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
    margin: 0 auto;
    display: inline-block;
    position: relative;
  }

  #image-wrapper > img {
    max-height: calc(100vh - 300px);
    min-height: 400px;
    width: 100%;
    border-radius: 2px;
    object-fit: contain;
    display: block;
  }
  #image-wrapper > .labels {
  }
</style>
