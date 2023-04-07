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

  const viewportWidth = ref(window.innerWidth)

  const resizeListener = () => {
    viewportWidth.value = window.innerWidth
  }

  onMounted(() => window.addEventListener('resize', resizeListener))
  onUnmounted(() => window.removeEventListener('resize', resizeListener))

  const imageWrapperWidth = computed(() => {
    if (viewportWidth.value < 768) {
      return 100
    } else if (props.photo.width != -1 && props.photo.height != -1) {
      const ratio = props.photo.width / props.photo.height
      console.log(ratio)
      if (ratio > 1.2) {
        // landscape
        return 100
      } else if (ratio >= 0.8 && ratio <= 1.2) {
        // square
        return 95
      } else {
        // portrait
        return 100 - (1 - ratio) * 100
      }
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
