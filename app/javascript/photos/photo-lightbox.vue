<template>
  <div
    v-if="isOpen"
    class="lightbox-overlay"
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

        <img
          ref="lightboxImage"
          :src="photo.extralargeImageUrl"
          :style="{ ...imageStyle, opacity: imageLoading ? 0 : 1 }"
          :alt="photo.title"
          @load="handleImageLoad"
          @error="handleImageError"
          draggable="false"
        />
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

// Image loading state
const imageLoading = ref(true);

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
const close = () => {
  resetZoom();
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

const handleResize = () => {
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
      imageLoading.value = true;
      nextTick(() => {
        updateContainerDimensions();
        resetZoom();
        showControls();
      });
    } else {
      clearTimeout(hideControlsTimeout.value);
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
