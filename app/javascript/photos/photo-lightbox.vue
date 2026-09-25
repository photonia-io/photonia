<template>
  <div
    v-if="isOpen"
    class="lightbox-overlay"
    :class="{ closing }"
    @click="handleOverlayClick"
    role="dialog"
    aria-modal="true"
    aria-label="Photo Lightbox"
  >
    <div class="lightbox-container">
      <!-- Controls -->
      <div
        class="lightbox-controls"
        :class="{ 'fade-out': controlsHidden }"
        role="toolbar"
        aria-label="Lightbox Controls"
      >
        <button
          @click="zoomIn"
          class="control-button"
          title="Zoom In"
          data-testid="zoom-in-button"
          :disabled="scale >= 2"
        >
          <ZoomInSVG />
        </button>
        <button
          @click="zoomOut"
          class="control-button"
          title="Zoom Out"
          data-testid="zoom-out-button"
          :disabled="scale <= 1"
        >
          <ZoomOutSVG />
        </button>
        <button
          @click="close"
          class="control-button"
          title="Close"
          data-testid="close-button"
        >
          <CloseSVG />
        </button>
      </div>

      <!-- Image container -->
      <div
        ref="imageContainer"
        class="image-container"
        @mousedown="startDrag"
        @mousemove="handleMouseMove"
        @mouseup="endDrag"
        @mouseleave="endDrag"
        @click="showControls"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="handleTouchEnd"
        @wheel="handleWheel"
      >
        <!-- Loading spinner -->
        <div v-if="loading || imageLoading" class="loading-spinner">
          <div class="spinner"></div>
        </div>

        <!-- Hi-res upgrade badge -->
        <div v-if="hiResLoading" class="hires-badge">
          <div class="hires-spinner"></div>
          <span>Loading higher resolution image...</span>
        </div>

        <div ref="frame" class="image-frame" :style="frameStyle">
          <img
            ref="lightboxImage"
            :src="displaySrc"
            :style="{ ...imageStyle, opacity: imageLoading ? 0 : 1 }"
            :alt="photo.title"
            @load="handleImageLoad"
            @error="handleImageError"
            draggable="false"
          />

          <!-- Hidden preload: swaps displaySrc in once it lands -->
          <img
            v-if="hiResLoading"
            :key="photo.extralargeImageUrl"
            :src="photo.extralargeImageUrl"
            class="hires-preload"
            alt=""
            @load="handleHiResLoad"
            @error="handleHiResError"
          />
        </div>
      </div>

      <!-- Title bar -->
      <div class="title-bar" :class="{ 'fade-out': controlsHidden }">
        <h3>{{ photo.title }}</h3>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from "vue";
import ZoomInSVG from "../shared/svg/zoom-in.vue";
import ZoomOutSVG from "../shared/svg/zoom-out.vue";
import CloseSVG from "../shared/svg/close.vue";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
  isOpen: {
    type: Boolean,
    required: true,
  },
  // The hero image's rect and currently-rendered src at the moment it was
  // clicked - lets the lightbox open by growing from there instead of
  // popping in, and start from whichever derivative the hero already had
  // on screen instead of a blank spinner.
  originRect: {
    type: Object,
    default: null,
  },
  initialSrc: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(["close"]);

// Reactive state
const scale = ref(1);
const translateX = ref(0);
const translateY = ref(0);
const isDragging = ref(false);
const dragStart = ref({ x: 0, y: 0 });
const imageContainer = ref(null);
const lightboxImage = ref(null);
const frame = ref(null);

// Image loading state
const imageLoading = ref(true);

// Prefer whatever the hero already had on screen, then the large derivative
// - both are usually cached already, so the spinner rarely shows.
const initialDisplaySrc = () =>
  props.photo.largeImageUrl || props.photo.extralargeImageUrl || "";

const displaySrc = ref(props.initialSrc || initialDisplaySrc());

// Set once the frame turns out to need more resolution than the currently
// displayed derivative offers; cleared once the extralarge swap lands (or
// fails) or the photo/lightbox changes underneath it.
const hiResLoading = ref(false);

// True while the close (shrink) animation is playing.
const closing = ref(false);

// Touch handling
const lastTouchDistance = ref(0);
const touchStartPos = ref({ x: 0, y: 0 });

// Controls visibility
const controlsHidden = ref(false);
const hideControlsTimeout = ref(null);

// Computed styles
const imageStyle = computed(() => ({
  transform: `scale(${scale.value}) translate(${translateX.value}px, ${translateY.value}px)`,
  transformOrigin: "center center",
  transition: isDragging.value ? "none" : "transform 0.3s ease",
  cursor:
    scale.value > 1 ? (isDragging.value ? "grabbing" : "grab") : "default",
}));

// Methods
const close = async () => {
  resetZoom();
  await playCloseAnimation();
  emit("close");
};

const handleOverlayClick = (event) => {
  if (event.target === event.currentTarget) {
    close();
  }
};

const zoomIn = () => {
  scale.value = Math.min(scale.value * 1.5, 2);
  constrainPosition();
  showControls();
};

const zoomOut = () => {
  scale.value = Math.max(scale.value / 1.5, 1);
  if (scale.value === 1) {
    translateX.value = 0;
    translateY.value = 0;
  } else {
    constrainPosition();
  }
  showControls();
};

const showControls = () => {
  controlsHidden.value = false;
  clearTimeout(hideControlsTimeout.value);
  hideControlsTimeout.value = setTimeout(() => {
    controlsHidden.value = true;
  }, 3000);
};

// Tracked separately from containerDimensions (which needs a DOM measurement
// after mount) because the overlay is always a full-viewport fixed box, so
// this is known synchronously - the frame is sized correctly from its very
// first paint instead of flashing at an unconstrained size for one frame
// before a later measurement corrects it.
const viewportSize = ref({ width: window.innerWidth, height: window.innerHeight });

const handleResize = () => {
  viewportSize.value = { width: window.innerWidth, height: window.innerHeight };
  updateContainerDimensions();
  constrainPosition();
};

onMounted(() => {
  window.addEventListener("resize", handleResize);
});

onUnmounted(() => {
  window.removeEventListener("resize", handleResize);
});

const handleImageLoad = () => {
  imageLoading.value = false;
  nextTick(() => {
    updateContainerDimensions();
    resetZoom();
  });
};

const handleImageError = () => {
  imageLoading.value = false;
};

const resetZoom = () => {
  scale.value = 1;
  translateX.value = 0;
  translateY.value = 0;
};

const containerDimensions = ref({ width: 0, height: 0 });

const updateContainerDimensions = () => {
  if (!imageContainer.value) return;
  const rect = imageContainer.value.getBoundingClientRect();
  containerDimensions.value = { width: rect.width, height: rect.height };
};

// The frame's own size: extralarge's aspect ratio, contained within the
// available space, capped at extralarge's native pixel size so a low-res
// photo is never stretched to fill the screen. Fixed independently of
// displaySrc, so swapping large for extralarge never shifts the layout.
// Sized from the viewport rather than a measured containerDimensions so it's
// correct on the very first render - see viewportSize above.
const frameSize = computed(() => {
  const dims = props.photo.extralargeDimensions;
  const { width: containerWidth, height: containerHeight } = viewportSize.value;
  if (!dims?.width || !dims?.height || !containerWidth || !containerHeight) {
    return null;
  }

  const ratio = dims.width / dims.height;
  const width = Math.min(containerWidth, dims.width, containerHeight * ratio);
  return { width, height: width / ratio };
});

// Set synchronously, in the same reactive update as the frame's first
// mount, so its very first render already carries the starting transform -
// see startOpenAnimation below for why that timing matters.
const frameTransformOverride = ref(null);

const frameStyle = computed(() => {
  if (!frameSize.value) return {};
  return {
    width: `${frameSize.value.width}px`,
    height: `${frameSize.value.height}px`,
    ...frameTransformOverride.value,
  };
});

// The frame is always centered in the full-viewport overlay (flex-centered,
// nothing else in flow), so its final position is knowable without ever
// measuring the DOM.
const finalFrameRect = computed(() => {
  if (!frameSize.value) return null;
  const { width: vw, height: vh } = viewportSize.value;
  return {
    left: (vw - frameSize.value.width) / 2,
    top: (vh - frameSize.value.height) / 2,
    width: frameSize.value.width,
    height: frameSize.value.height,
  };
});

// True once the frame, at the current zoom and pixel ratio, actually needs
// more detail than the displayed derivative offers - so zooming into a
// `large` image can trigger the upgrade too.
const needsExtralarge = computed(() => {
  const extralargeUrl = props.photo.extralargeImageUrl;
  const largeWidth = props.photo.largeDimensions?.width;
  if (!extralargeUrl || !largeWidth || !frameSize.value) return false;
  if (displaySrc.value === extralargeUrl) return false;

  const requiredWidth =
    frameSize.value.width * (window.devicePixelRatio || 1) * scale.value;
  return requiredWidth > largeWidth;
});

// Re-checked on open and photo change, and flushed "post" so it runs after
// the open/photo watchers have reset hiResLoading.
watch(
  () => [needsExtralarge.value, props.isOpen, props.photo.extralargeImageUrl],
  ([needed, open]) => {
    if (needed && open) hiResLoading.value = true;
  },
  { immediate: true, flush: "post" },
);

// Ignores a load that belongs to a photo we've since navigated away from.
const handleHiResLoad = (event) => {
  if (event.target.getAttribute("src") !== props.photo.extralargeImageUrl) {
    return;
  }
  displaySrc.value = props.photo.extralargeImageUrl;
  hiResLoading.value = false;
};

const handleHiResError = () => {
  hiResLoading.value = false;
};

const prefersReducedMotion = () =>
  window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;

// dx/dy/scale to take a rect down to the origin rect - shared by open
// (origin <- finalFrameRect, no DOM measurement needed) and close
// (origin <- the frame's live rect).
const transformToRect = (rect, origin) => {
  if (!rect || !rect.width || !rect.height) return null;

  const scaleFactor = origin.width / rect.width;
  const dx = origin.left + origin.width / 2 - (rect.left + rect.width / 2);
  const dy = origin.top + origin.height / 2 - (rect.top + rect.height / 2);

  return `translate(${dx}px, ${dy}px) scale(${scaleFactor})`;
};

// FLIP, but the starting transform is set as part of the same reactive
// update that first mounts the frame (via frameTransformOverride, computed
// from finalFrameRect rather than measured), not after. Measuring the DOM
// and correcting it afterwards - even from a nextTick callback - leaves a
// window where the frame can paint once at its full target size before the
// correction lands, which flashes. Baking the start state into the initial
// render removes that window entirely.
const startOpenAnimation = () => {
  if (!props.originRect || prefersReducedMotion()) {
    frameTransformOverride.value = null;
    return false;
  }

  const startTransform = transformToRect(finalFrameRect.value, props.originRect);
  if (!startTransform) {
    frameTransformOverride.value = null;
    return false;
  }

  frameTransformOverride.value = { transform: startTransform, transition: "none" };
  return true;
};

// Called once the frame (with its starting transform already applied) has
// actually mounted - the double rAF makes sure that first paint has landed
// before switching to the transition that grows it to full size.
const settleOpenAnimation = () => {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      frameTransformOverride.value = {
        transform: "none",
        transition: "transform 350ms ease",
      };
    });
  });
};

// The reverse: shrink the frame back down to the hero's rect before actually
// closing, so the lightbox and the hero image trade places smoothly instead
// of the lightbox just vanishing. Resolves once the shrink has finished (or
// immediately, if there's nothing to animate) so `close` can wait for it.
// Unlike open, this measures the frame's live rect - it's already mounted
// and visible, so there's no flash window to worry about.
const playCloseAnimation = () =>
  new Promise((resolve) => {
    const frameEl = frame.value;
    if (!props.originRect || prefersReducedMotion() || !frameEl) {
      resolve();
      return;
    }

    const endTransform = transformToRect(
      frameEl.getBoundingClientRect(),
      props.originRect,
    );
    if (!endTransform) {
      resolve();
      return;
    }

    closing.value = true;

    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      frameEl.removeEventListener("transitionend", finish);
      closing.value = false;
      resolve();
    };

    frameEl.addEventListener("transitionend", finish);
    // transitionend can fail to fire (element removed, style pre-empted) -
    // this is the fallback so closing never gets stuck true.
    setTimeout(finish, 400);

    // Through the bound style, not frameEl.style: Vue re-applies every key
    // of frameStyle on each render, which would snap an imperative write back.
    frameTransformOverride.value = {
      transform: endTransform,
      transition: "transform 350ms ease",
    };
  });

const constrainPosition = () => {
  if (!lightboxImage.value || !imageContainer.value) return;

  const img = lightboxImage.value;
  const imgRect = img.getBoundingClientRect();

  const scaledWidth = imgRect.width;
  const scaledHeight = imgRect.height;

  const maxTranslateX = Math.max(
    0,
    (scaledWidth - containerDimensions.value.width) / 2,
  );
  const maxTranslateY = Math.max(
    0,
    (scaledHeight - containerDimensions.value.height) / 2,
  );

  translateX.value = Math.max(
    -maxTranslateX,
    Math.min(maxTranslateX, translateX.value),
  );
  translateY.value = Math.max(
    -maxTranslateY,
    Math.min(maxTranslateY, translateY.value),
  );
};

// Mouse drag handlers
const startDrag = (event) => {
  if (scale.value <= 1) return;

  isDragging.value = true;
  dragStart.value = {
    x: event.clientX - translateX.value,
    y: event.clientY - translateY.value,
  };
  event.preventDefault();
};

const handleMouseMove = (event) => {
  showControls();
  drag(event);
};

const drag = (event) => {
  if (!isDragging.value || scale.value <= 1) return;

  translateX.value = event.clientX - dragStart.value.x;
  translateY.value = event.clientY - dragStart.value.y;
  constrainPosition();
};

const endDrag = () => {
  isDragging.value = false;
};

// Touch handlers
const handleTouchStart = (event) => {
  showControls();
  if (event.touches.length === 1) {
    // Single touch - start drag
    if (scale.value > 1) {
      const touch = event.touches[0];
      touchStartPos.value = { x: touch.clientX, y: touch.clientY };
      dragStart.value = {
        x: touch.clientX - translateX.value,
        y: touch.clientY - translateY.value,
      };
      isDragging.value = true;
    }
  } else if (event.touches.length === 2) {
    // Two touches - start pinch
    const touch1 = event.touches[0];
    const touch2 = event.touches[1];
    const distance = Math.sqrt(
      Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2),
    );
    lastTouchDistance.value = distance;
    isDragging.value = false;
  }
  event.preventDefault();
};

const handleTouchMove = (event) => {
  if (event.touches.length === 1 && isDragging.value && scale.value > 1) {
    // Single touch drag
    const touch = event.touches[0];
    translateX.value = touch.clientX - dragStart.value.x;
    translateY.value = touch.clientY - dragStart.value.y;
    constrainPosition();
  } else if (event.touches.length === 2) {
    // Pinch zoom
    const touch1 = event.touches[0];
    const touch2 = event.touches[1];
    const distance = Math.sqrt(
      Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2),
    );

    if (lastTouchDistance.value > 0) {
      const scaleChange = distance / lastTouchDistance.value;
      scale.value = Math.max(1, Math.min(2, scale.value * scaleChange));
      if (scale.value === 1) {
        translateX.value = 0;
        translateY.value = 0;
      } else {
        constrainPosition();
      }
    }

    lastTouchDistance.value = distance;
  }
  event.preventDefault();
};

const handleTouchEnd = () => {
  isDragging.value = false;
  lastTouchDistance.value = 0;
};

// Wheel zoom
const handleWheel = (event) => {
  event.preventDefault();
  showControls();
  const delta = event.deltaY > 0 ? 0.9 : 1.1;
  scale.value = Math.max(1, Math.min(2, scale.value * delta));
  if (scale.value === 1) {
    translateX.value = 0;
    translateY.value = 0;
  } else {
    constrainPosition();
  }
};

// Watch for photo changes and reset zoom
watch(
  () => props.photo,
  () => {
    if (props.isOpen) {
      // originRect/initialSrc belong to whichever photo was clicked to open
      // the lightbox - a photo swap while it's already open (e.g. next/prev)
      // has no hero rect to speak of, so it always starts from `large`.
      displaySrc.value = initialDisplaySrc();
      hiResLoading.value = false;
      imageLoading.value = true;
      nextTick(() => {
        resetZoom();
      });
    }
  },
  { deep: true },
);

// Watch for lightbox open/close
watch(
  () => props.isOpen,
  (newValue) => {
    if (newValue) {
      displaySrc.value = props.initialSrc || initialDisplaySrc();
      hiResLoading.value = false;
      // The hero's own src is already on screen, so don't hide it until a
      // load event - that blanked the photo for a frame on open.
      imageLoading.value = !props.initialSrc;
      // Set here, not inside nextTick below - it needs to land in the same
      // render as the frame's first mount (see startOpenAnimation).
      const animating = startOpenAnimation();
      nextTick(() => {
        updateContainerDimensions();
        resetZoom();
        showControls();
        if (animating) settleOpenAnimation();
      });
    } else {
      clearTimeout(hideControlsTimeout.value);
      hiResLoading.value = false;
    }
  },
);

// Keyboard handling
const handleKeydown = (event) => {
  if (!props.isOpen) return;

  if (event.key === "Escape") {
    close();
  } else if (event.key === "+" || event.key === "=") {
    zoomIn();
  } else if (event.key === "-") {
    zoomOut();
  }
  showControls();
};

// Add/remove keyboard listener
watch(
  () => props.isOpen,
  (newValue) => {
    if (newValue) {
      nextTick(() => {
        resetZoom();
        showControls();
      });
      document.addEventListener("keydown", handleKeydown);
      document.body.style.overflow = "hidden";
    } else {
      clearTimeout(hideControlsTimeout.value);
      document.removeEventListener("keydown", handleKeydown);
      document.body.style.overflow = "";
    }
  },
);
</script>

<style scoped lang="scss">
// Only the backdrop fades in - fading the whole overlay also faded the photo,
// which blinked out while the hero underneath was already hidden.
@keyframes lightbox-fade-in {
  from {
    background-color: rgba(0, 0, 0, 0);
  }
}

.lightbox-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.95);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: lightbox-fade-in 300ms ease;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }

  // Only the backdrop and chrome fade while the frame shrinks - fading the
  // whole overlay would fade the photo too.
  &.closing {
    animation: none;
    background-color: rgba(0, 0, 0, 0);
    transition: background-color 350ms ease;

    .lightbox-controls,
    .title-bar,
    .hires-badge {
      opacity: 0;
    }
  }
}

.lightbox-container {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.lightbox-controls {
  position: absolute;
  top: 20px;
  right: 20px;
  z-index: 10001;
  display: flex;
  gap: 10px;
  transition: opacity 0.3s ease;

  &.fade-out {
    opacity: 0;
    pointer-events: none;
  }
}

.control-button {
  background: rgba(0, 0, 0, 0.7);
  border: none;
  border-radius: 50%;
  width: 48px;
  height: 48px;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s ease;

  &:hover:not(:disabled) {
    background: rgba(0, 0, 0, 0.9);
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  svg {
    width: 24px;
    height: 24px;
  }
}

.image-container {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  position: relative;
}

// A fixed-size box: extralarge's aspect ratio contained within the
// available space and capped at its native pixel size (set inline via
// frameStyle). Its size never depends on which derivative is displayed, so
// swapping large for extralarge never shifts the layout - and it's the
// target of the open animation.
.image-frame {
  position: relative;
}

.image-container img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  transition: opacity 0.3s ease-in-out;
}

.image-frame img {
  width: 100%;
  height: 100%;
}

// Kept in the DOM (not display: none) so the browser actually fetches it.
.hires-preload {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
  pointer-events: none;
}

.hires-badge {
  position: absolute;
  top: 20px;
  left: 20px;
  z-index: 10001;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.85rem;
  padding: 8px 14px;
  border-radius: 20px;
}

.hires-spinner {
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top: 2px solid #ffffff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
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

.title-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 15px 20px;
  text-align: center;
  transition: opacity 0.3s ease;

  &.fade-out {
    opacity: 0;
    pointer-events: none;
  }

  h3 {
    margin: 0;
    font-size: 1.2rem;
    font-weight: 500;
  }
}

@media (max-width: 768px) {
  .lightbox-controls {
    top: 10px;
    right: 10px;
  }

  .control-button {
    width: 40px;
    height: 40px;

    svg {
      width: 20px;
      height: 20px;
    }
  }

  .title-bar {
    padding: 10px 15px;

    h3 {
      font-size: 1rem;
    }
  }
}
</style>
