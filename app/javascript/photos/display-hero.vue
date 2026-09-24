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
        :style="{
          '--photo-ratio': ratio,
          '--photo-width': nativeWidth,
          '--target-ratio': ratio,
          '--target-width': nativeWidth,
        }"
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
        <div v-if="isHomepage && photo.id" class="overlay">
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

// 0 while the new image is downloading, 0.6 while the previous photo is
// being held on screen during a navigation, 1 otherwise. It no longer waits
// on the box: the photo is sized from --target-*, which never animates, so
// it can fade in over the morph without ever being scaled by it.
const heroOpacity = computed(() => {
  if (imageLoading.value) return 0;
  if (props.loading) return 0.6;
  return 1;
});

// The hide must be instant, not a fade: --target-* snaps to the incoming
// photo's dimensions the moment its data arrives, so the outgoing bitmap
// would visibly jump to the new size if it were still fading out.
const imageStyle = computed(() => ({
  opacity: heroOpacity.value,
  transition: imageLoading.value ? "none" : "opacity 300ms ease-in-out",
}));

// Genuine waiting only - the query in flight or the image still
// downloading. The morph deliberately doesn't count: it's a cosmetic
// animation we chose to run, not something being waited on. imageLoading
// only counts when there's a URL to load: with none there's no <img> to
// fire load or error, so it would otherwise stay true forever (a photo
// whose derivatives haven't been generated yet) and spin indefinitely.
const isBusy = computed(() => {
  return (
    props.loading ||
    (Boolean(props.photo.extralargeImageUrl) && imageLoading.value)
  );
});

// There's no way to ask the browser whether the image is cached, but the
// same problem is better solved by not caring: don't show the spinner
// until isBusy has stayed true for a bit. A cached image (or anything else
// that resolves fast - a warm CDN, a quick LAN round trip) settles within
// that window and never shows a spinner at all, rather than flashing one
// for something too fast to mean anything.
const SPINNER_DELAY_MS = 150;
const showSpinner = ref(false);
let spinnerDelayTimer = null;

// immediate, because isBusy is already true at mount (imageLoading starts
// true): without it a slow first page load would never arm the timer, and
// so would never show a spinner at all.
watch(
  isBusy,
  (busy) => {
    clearTimeout(spinnerDelayTimer);
    if (busy) {
      spinnerDelayTimer = setTimeout(() => {
        showSpinner.value = true;
      }, SPINNER_DELAY_MS);
    } else {
      showSpinner.value = false;
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => clearTimeout(spinnerDelayTimer));

const showLabels = computed(() => {
  return (
    applicationStore.showLabelsOnHero &&
    !props.loading &&
    props.photo.labels?.length > 0
  );
});
</script>

<style scoped lang="scss">
// --photo-* are eased (they drive the animating height); --target-* are the
// same values applied instantly, so anything sized from them never scales
// mid-animation. Both must inherit: ::before and the image read them.
@property --photo-ratio {
  syntax: "<number>";
  inherits: true;
  initial-value: 1.5;
}

@property --photo-width {
  syntax: "<number>";
  inherits: true;
  initial-value: 1200;
}

@property --target-ratio {
  syntax: "<number>";
  inherits: true;
  initial-value: 1.5;
}

@property --target-width {
  syntax: "<number>";
  inherits: true;
  initial-value: 1200;
}

// Never upscale past the displayed derivative's own resolution: whichever
// constraint is smallest wins - the container's width, the derivative's
// native pixel width, or the width implied by the height ceiling. Small
// photos display small; the hero's height genuinely varies per photo
// rather than always filling to the ceiling.
@mixin photo-box($ratio, $width) {
  width: min(
    100%,
    calc(#{$width} * 1px),
    calc(var(--hero-max-height) * #{$ratio})
  );
}

// Deliberately full-width and not animated, so it stays a stable sizing
// reference: everything inside resolves its own `100%` against the hero
// body's width rather than against a box that's mid-morph.
#image-wrapper {
  --hero-max-height: calc(100vh - 150px);

  position: relative;
  display: block;
  width: 100%;
  overflow: hidden;

  // The morph. Invisible - it exists only to give the wrapper its height,
  // which is what drives the hero's height and the page layout below it.
  &::before {
    content: "";
    display: block;
    margin: 0 auto;
    aspect-ratio: var(--photo-ratio);
    @include photo-box(var(--photo-ratio), var(--photo-width));
  }

  &.is-animated {
    transition: --photo-ratio 350ms ease, --photo-width 350ms ease;
  }
}

// Sized from --target-*, so the photo is at its final size from the first
// frame and the morph happens around it, never to it. While the wrapper is
// shorter than the photo (a growing morph) overflow: hidden above crops it,
// so it's uncovered rather than stretched.
#image-wrapper > a,
#image-wrapper > img {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  height: auto;
  aspect-ratio: var(--target-ratio);
  @include photo-box(var(--target-ratio), var(--target-width));
}

#image-wrapper img {
  display: block;
  object-fit: contain;
  border-radius: 2px;
  // transition itself is set inline (imageStyle) - the hide must be instant,
  // only the reveal fades, so it can't be a single static rule here.
}

#image-wrapper > a img {
  width: 100%;
  height: 100%;
}

/* remove padding from hero-body when on mobile */
@media (max-width: 1023px) {
  .hero-body {
    padding: 0 !important;
  }
}

// Both of these used to inherit the photo's box for free, back when the
// wrapper was the photo box. It's full-width now, so they have to take the
// photo's geometry themselves to stay aligned to the image.
.overlay {
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.5);
  @include photo-box(var(--target-ratio), var(--target-width));
}

// Positioned so the Rekognition label boxes inside, which are placed in
// percentages, resolve against the photo rather than the full-width wrapper.
.labels {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  height: auto;
  aspect-ratio: var(--target-ratio);
  @include photo-box(var(--target-ratio), var(--target-width));
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
