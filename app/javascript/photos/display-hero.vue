<template>
  <div class="hero is-dark mb-3">
    <div class="hero-body pt-4 pb-4" style="text-align: center;">
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

<style scoped lang="scss">
  #image-wrapper {
    margin: 0 auto;
    display: inline-block;
    position: relative;
  }

  #image-wrapper > img {
    max-height: calc(100vh - 150px);
    width: 100%;
    border-radius: 2px;
    object-fit: contain;
    display: inline-block;
    vertical-align: top;

    @media (min-width: 1024px) {
      min-height: 400px;
    }
  }

  /* remove padding from hero-body when on mobile */
  @media (max-width: 1023px) {
    .hero-body {
      padding: 0 !important;
    }
  }

  #image-wrapper > .labels {
  }
</style>
