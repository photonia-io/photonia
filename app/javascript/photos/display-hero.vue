<template>
  <div class="hero is-dark mb-3">
    <div id="label-list" v-if="showLabels">
      <span class="label-list-title">Labels</span>
      <LabelListItem
        v-for="label in photo.labels"
        @highlight-label="$emit('highlightLabel', $event)"
        @un-highlight-label="$emit('unHighlightLabel', $event)"
        :label="label"
        :hoverable="true"
        :key="label.id"
      />
    </div>
    <div class="hero-body pt-4 pb-4" style="text-align: center">
      <div id="image-wrapper">
        <!-- Loading spinner -->
        <div v-if="loading || imageLoading" class="loading-spinner">
          <div class="spinner"></div>
        </div>

        <router-link
          v-if="isHomepage"
          :to="{ name: 'photos-show', params: { id: photo.id } }"
        >
          <img
            :src="photo.extralargeImageUrl"
            @load="onImageLoad"
            @error="onImageError"
            :style="{ opacity: imageLoading ? 0 : 1 }"
          />
        </router-link>
        <img
          v-else
          :src="photo.extralargeImageUrl"
          :alt="photo.title"
          @click="openLightbox"
          @load="onImageLoad"
          @error="onImageError"
          :style="{ cursor: 'pointer', opacity: imageLoading ? 0 : 1 }"
        />
        <div v-if="showLabels" class="labels">
          <DisplayLabel
            v-for="label in photo.labels"
            :label="label"
            :highlighted="labelHighlights[label.id]"
            :key="label.id"
          />
        </div>
        <div v-if="isHomepage" class="overlay">
          <div class="level p-2">
            <div class="level-left pl-3">
              <p class="is-size-4">
                Latest photo:
                <router-link
                  :to="{ name: 'photos-show', params: { id: photo.id } }"
                >
                  {{ photo.title }}
                </router-link>
              </p>
            </div>
            <div class="level-right has-text-right pr-3">
              <router-link :to="{ name: 'photos-index' }" class="button">
                See all photos...
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Lightbox -->
    <PhotoLightbox
      :photo="photo"
      :loading="loading"
      :is-open="lightboxOpen"
      @close="closeLightbox"
    />
  </div>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import DisplayLabel from "./display-label.vue";
import LabelListItem from "./label-list-item.vue";
import PhotoLightbox from "./photo-lightbox.vue";
import { useApplicationStore } from "@/stores/application";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  labelHighlights: {
    type: Object,
    required: false,
  },
  isHomepage: {
    type: Boolean,
    required: false,
    default: false,
  },
  loading: {
    type: Boolean,
    required: false,
    default: false,
  },
});

const emit = defineEmits(["highlightLabel", "unHighlightLabel"]);

const applicationStore = useApplicationStore();

// Lightbox state
const lightboxOpen = ref(false);

// Image loading state
const imageLoading = ref(true);

// Reset loading state when photo changes
watch(
  () => props.photo.id,
  () => {
    imageLoading.value = true;
  },
);

const openLightbox = () => {
  lightboxOpen.value = true;
};

const closeLightbox = () => {
  lightboxOpen.value = false;
};

const onImageLoad = () => {
  imageLoading.value = false;
};

const onImageError = () => {
  imageLoading.value = false;
};

const showLabels = computed(() => {
  return (
    applicationStore.showLabelsOnHero &&
    !props.loading &&
    props.photo.labels?.length > 0
  );
});
</script>

<style scoped lang="scss">
#image-wrapper {
  margin: 0 auto;
  display: inline-block;
  position: relative;
}

#image-wrapper img {
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

.overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  background: rgba(0, 0, 0, 0.5);
}

.hero {
  position: relative;
}

#label-list {
  position: absolute;
  top: 0;
  right: 0;
  z-index: 100;
  background: rgba(0, 0, 0, 0.3);
  margin: 0.5rem 0.5rem 0 0;
  padding: 0.3em;
  width: auto;
  display: flex;
  flex-direction: column;
  border-radius: 5px;
  overflow: auto;
  max-height: calc(100% - 15px);
}

.label-list-title {
  font-size: 0.8rem;
  margin: 0 0.2rem 0.2rem;
  font-weight: bold;
}

#label-list .tag {
  text-align: left;
  margin: 0.2rem;
}

.loading-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 10;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top: 4px solid #ffffff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

#image-wrapper img {
  transition: opacity 0.3s ease-in-out;
}

// #image-wrapper > .overlay {
//   position: absolute;
//   top: 0;
//   left: 0;
//   width: 100%;
//   height: 100%;
//   background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5));
//   display: flex;
//   align-items: center;
//   justify-content: center;
// }
</style>
