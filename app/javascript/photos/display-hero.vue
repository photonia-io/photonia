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
      <div
        id="image-wrapper"
        :class="{ 'is-animated': animated }"
        :style="{ '--photo-ratio': ratio, '--photo-width': nativeWidth }"
        @transitionend="onBoxTransitionEnd"
      >
        <!-- Loading spinner -->
        <div v-if="showSpinner" class="loading-spinner">
          <div class="spinner"></div>
        </div>

        <template v-if="photo.extralargeImageUrl">
          <router-link
            v-if="isHomepage"
            :to="{ name: 'photos-show', params: { id: photo.id } }"
          >
            <img
              :src="photo.extralargeImageUrl"
              @load="onImageLoad"
              @error="onImageError"
              :style="imageStyle"
            />
          </router-link>
          <img
            v-else
            :src="photo.extralargeImageUrl"
            :alt="photo.title"
            @click="openLightbox"
            @load="onImageLoad"
            @error="onImageError"
            :style="{ cursor: 'pointer', ...imageStyle }"
          />
        </template>
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
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import DisplayLabel from "./display-label.vue";
import LabelListItem from "./label-list-item.vue";
import PhotoLightbox from "./photo-lightbox.vue";
import { useApplicationStore } from "@/stores/application";

const props = defineProps({
  photo: {
    type: Object,
    required: false,
    default: () => ({}),
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

// Reserved box shape, driven by the displayed derivative's real dimensions -
// never the original's, which can disagree when the original carries an
// EXIF rotation flag. ratio sizes the box; nativeWidth caps it so photos are
// never upscaled past their own resolution. Both fall back to a plausible
// value until the first real dimensions arrive, and are never reset to that
// fallback afterwards, so during next/prev the box holds the outgoing
// photo's shape until the incoming one is known.
const ratio = ref(3 / 2);
const nativeWidth = ref(1200);

// Only the very first real ratio should apply without a transition, so a
// fresh page load settles once, together with the rest of the page, rather
// than visibly animating in.
const animated = ref(false);
let animationEnabled = false;

// Slightly longer than #image-wrapper.is-animated's transition-duration
// below - only a safety net for when transitionend doesn't fire (e.g. the
// incoming photo happens to share the outgoing one's exact ratio and native
// width, so nothing actually animates), never the primary signal.
const BOX_TRANSITION_FALLBACK_MS = 500;

// True once the box has finished animating to the incoming photo's shape.
// A cached image can fire "load" almost instantly - far faster than the box
// transition - so gating the reveal on imageLoading alone would show the
// image while the box is still resizing under it, making the photo itself
// look like it's growing or shrinking. Starts true: there's nothing to wait
// for until a navigation actually starts an animated transition.
const boxSettled = ref(true);
let boxSettleFallbackTimer = null;

const settleBox = () => {
  clearTimeout(boxSettleFallbackTimer);
  boxSettled.value = true;
};

// Real signal that the box has reached its new shape, rather than a guessed
// duration that has to be kept in sync with the CSS by hand.
const onBoxTransitionEnd = (event) => {
  if (event.target !== event.currentTarget) return; // ignore the img's own opacity transition bubbling up
  if (event.propertyName !== "--photo-ratio" && event.propertyName !== "--photo-width") return;
  settleBox();
};

onBeforeUnmount(() => clearTimeout(boxSettleFallbackTimer));

watch(
  () => props.photo.extralargeDimensions,
  (dimensions) => {
    if (dimensions?.width > 0 && dimensions?.height > 0) {
      ratio.value = dimensions.width / dimensions.height;
      nativeWidth.value = dimensions.width;

      if (!animationEnabled) {
        animationEnabled = true;
        nextTick(() => {
          requestAnimationFrame(() => {
            animated.value = true;
          });
        });
      }
    }
  },
  { immediate: true },
);

// Reset loading state when photo changes
watch(
  () => props.photo.id,
  () => {
    imageLoading.value = true;

    // Only an actual navigation (not the first-ever load, which never
    // animates) needs the reveal gated on the box settling.
    if (animated.value) {
      boxSettled.value = false;
      clearTimeout(boxSettleFallbackTimer);
      boxSettleFallbackTimer = setTimeout(settleBox, BOX_TRANSITION_FALLBACK_MS);
    }
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

// 0 while the new image is downloading or the box is still resizing to its
// shape, 0.6 while the previous photo is being held on screen during a
// navigation, 1 otherwise.
const heroOpacity = computed(() => {
  if (imageLoading.value || !boxSettled.value) return 0;
  if (props.loading) return 0.6;
  return 1;
});

// The hide (triggered by imageLoading going true at the start of a
// navigation) must be instant, not a fade: #image-wrapper's resize starts
// at that exact moment, and a 300ms fade-out would stay visible - and
// visibly resize - throughout it. Only the later reveal should be smooth.
const imageStyle = computed(() => ({
  opacity: heroOpacity.value,
  transition: imageLoading.value ? "none" : "opacity 300ms ease-in-out",
}));

// Covers the same span as heroOpacity's hidden state, plus the initial
// "a navigation has started but the new photo hasn't arrived yet" moment
// (props.loading, when the old image is only dimmed rather than hidden).
const showSpinner = computed(() => {
  return props.loading || imageLoading.value || !boxSettled.value;
});

const showLabels = computed(() => {
  return (
    applicationStore.showLabelsOnHero &&
    !props.loading &&
    props.photo.labels?.length > 0
  );
});
</script>

<style scoped lang="scss">
@property --photo-ratio {
  syntax: "<number>";
  inherits: false;
  initial-value: 1.5;
}

@property --photo-width {
  syntax: "<number>";
  inherits: false;
  initial-value: 1200;
}

#image-wrapper {
  --hero-max-height: calc(100vh - 150px);

  position: relative;
  display: block;
  margin: 0 auto;
  aspect-ratio: var(--photo-ratio);
  // Never upscale past the displayed derivative's own resolution: whichever
  // constraint is smallest wins - the container's width, the derivative's
  // native pixel width, or the width implied by the height ceiling. Small
  // photos display small; the hero's height genuinely varies per photo
  // rather than always filling to the ceiling.
  width: min(
    100%,
    calc(var(--photo-width) * 1px),
    calc(var(--hero-max-height) * var(--photo-ratio))
  );

  &.is-animated {
    transition: --photo-ratio 350ms ease, --photo-width 350ms ease;
  }
}

#image-wrapper > a {
  display: block;
  width: 100%;
  height: 100%;
}

#image-wrapper img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
  border-radius: 2px;
  // transition itself is set inline (imageStyle) - the hide must be instant,
  // only the reveal fades, so it can't be a single static rule here.
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
</style>
