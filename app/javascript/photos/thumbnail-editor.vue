<template>
  <div class="thumbnail-editor" v-if="editMode">
    <div class="editor-container">
      <div class="image-wrapper">
        <div class="image-container" ref="imageContainer">
          <img
            ref="image"
            :src="photo.extralargeImageUrl"
            alt="Photo for thumbnail editing"
            @load="onImageLoad"
          />
          <div
            v-if="imageLoaded"
            class="thumbnail-box"
            :style="thumbnailStyle"
            @mousedown="onDragStart"
          >
            <div class="resize-handle" @mousedown.stop="onResizeStart"></div>
          </div>
        </div>
      </div>
      <div class="editor-controls">
        <button class="button is-success" @click="saveThumbnail">
          <span class="icon">
            <i class="fas fa-save"></i>
          </span>
          <span>Save Thumbnail</span>
        </button>
        <button class="button" @click="cancelEdit">
          <span class="icon">
            <i class="fas fa-times"></i>
          </span>
          <span>Cancel</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from "vue";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  editMode: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(["save", "cancel"]);

// Refs
const imageContainer = ref(null);
const image = ref(null);
const imageLoaded = ref(false);

// Thumbnail bounding box
// top/left: percentages of container dimensions (0-1)
// width/height: uniform size as percentage of smaller container dimension (0-1)
const thumbnail = ref({
  top: 0.25,
  left: 0.25,
  width: 0.5,
  height: 0.5,
});

// Dragging state
const isDragging = ref(false);
const isResizing = ref(false);
const dragStartX = ref(0);
const dragStartY = ref(0);
const startThumbnail = ref(null);

// Container dimensions
const containerWidth = ref(0);
const containerHeight = ref(0);

// Helper functions
const initializeThumbnail = () => {
  if (props.photo.userThumbnail) {
    // When loading from saved data, width and height are percentages of actual dimensions
    // We need to convert to a uniform size representation
    // Calculate the pixel size from both dimensions and use the smaller one
    const widthPx = props.photo.userThumbnail.width * containerWidth.value;
    const heightPx = props.photo.userThumbnail.height * containerHeight.value;
    const squareSizePx = Math.min(widthPx, heightPx);

    // Convert back to a uniform percentage (based on smaller container dimension)
    const uniformSize =
      squareSizePx / Math.min(containerWidth.value, containerHeight.value);

    return {
      top: props.photo.userThumbnail.top,
      left: props.photo.userThumbnail.left,
      width: uniformSize,
      height: uniformSize,
    };
  } else if (props.photo.intelligentThumbnail) {
    const bbox = props.photo.intelligentThumbnail.boundingBox;
    // For intelligent thumbnail, convert dimension-specific percentages to uniform size
    // Calculate pixel size from both dimensions and use the smaller one to ensure it fits
    const widthPx = bbox.width * containerWidth.value;
    const heightPx = bbox.height * containerHeight.value;
    const squareSizePx = Math.min(widthPx, heightPx);

    const uniformSize =
      squareSizePx / Math.min(containerWidth.value, containerHeight.value);

    return {
      top: bbox.top,
      left: bbox.left,
      width: uniformSize,
      height: uniformSize,
    };
  } else {
    // Default: center the thumbnail with full height (landscape) or full width (portrait)
    // Determine if landscape or portrait based on container dimensions
    const isLandscape = containerWidth.value >= containerHeight.value;

    if (isLandscape) {
      // Landscape: use full height (uniformSize = 1.0), center horizontally
      const uniformSize = 1.0; // 100% of the smaller dimension (height)
      const squareSizePx = calculateSquareSize(uniformSize);
      const widthPercent = squareSizePx / containerWidth.value;
      const left = (1.0 - widthPercent) / 2; // Center horizontally

      return {
        top: 0.0,
        left: left,
        width: uniformSize,
        height: uniformSize,
      };
    } else {
      // Portrait: use full width (uniformSize = 1.0), center vertically
      const uniformSize = 1.0; // 100% of the smaller dimension (width)
      const squareSizePx = calculateSquareSize(uniformSize);
      const heightPercent = squareSizePx / containerHeight.value;
      const top = (1.0 - heightPercent) / 2; // Center vertically

      return {
        top: top,
        left: 0.0,
        width: uniformSize,
        height: uniformSize,
      };
    }
  }
};

const updateContainerDimensions = () => {
  if (image.value) {
    // Use the actual rendered dimensions of the image
    const rect = image.value.getBoundingClientRect();
    containerWidth.value = rect.width;
    containerHeight.value = rect.height;
  }
};

const calculateSquareSize = (uniformSize) => {
  // Convert uniform size (percentage of smaller dimension) to pixels
  // Since width and height are equal (uniform size), we can use either
  const widthPx = uniformSize * containerWidth.value;
  const heightPx = uniformSize * containerHeight.value;
  // Return the smaller dimension to get actual square size in pixels
  return Math.min(widthPx, heightPx);
};

const constrainPosition = (left, top, uniformSize) => {
  // Convert uniform size to actual square size in pixels
  const widthPx = uniformSize * containerWidth.value;
  const heightPx = uniformSize * containerHeight.value;
  const squareSizePx = Math.min(widthPx, heightPx);

  // Calculate how much space the square takes as a percentage of each dimension
  const sizePercentWidth = squareSizePx / containerWidth.value;
  const sizePercentHeight = squareSizePx / containerHeight.value;

  // Ensure square stays within image bounds (0 to 1-size)
  const newLeft = Math.max(0, Math.min(1 - sizePercentWidth, left));
  const newTop = Math.max(0, Math.min(1 - sizePercentHeight, top));

  return { left: newLeft, top: newTop };
};

const handleDrag = (deltaX, deltaY) => {
  // Calculate new position
  let newLeft = startThumbnail.value.left + deltaX;
  let newTop = startThumbnail.value.top + deltaY;

  // Get the uniform size (width and height are equal in our representation)
  const size = startThumbnail.value.width;

  // Constrain to image bounds
  const { left: constrainedLeft, top: constrainedTop } = constrainPosition(
    newLeft,
    newTop,
    size,
  );

  thumbnail.value.left = constrainedLeft;
  thumbnail.value.top = constrainedTop;
  // Keep width and height unchanged during drag
  thumbnail.value.width = startThumbnail.value.width;
  thumbnail.value.height = startThumbnail.value.height;
};

const handleResize = (deltaXPx, deltaYPx) => {
  // Use the larger delta to make resizing more responsive
  const deltaMax = Math.max(deltaXPx, deltaYPx);
  // Convert pixel delta to uniform size percentage (based on smaller dimension)
  const deltaSize =
    deltaMax / Math.min(containerWidth.value, containerHeight.value);

  // Start size is already uniform (width and height are equal)
  const startSize = startThumbnail.value.width;
  let newSize = startSize + deltaSize;

  // Calculate maximum allowed size based on position
  const maxWidthPercent = 1 - startThumbnail.value.left;
  const maxHeightPercent = 1 - startThumbnail.value.top;
  const maxWidthPx = maxWidthPercent * containerWidth.value;
  const maxHeightPx = maxHeightPercent * containerHeight.value;
  const maxSizePx = Math.min(maxWidthPx, maxHeightPx);

  // Convert max size back to uniform percentage (based on smaller dimension)
  const maxSize =
    maxSizePx / Math.min(containerWidth.value, containerHeight.value);

  // Constrain size: minimum 10%, maximum based on position
  newSize = Math.max(0.1, Math.min(maxSize, newSize));

  // Update both width and height with the same uniform size
  thumbnail.value.width = newSize;
  thumbnail.value.height = newSize;
};

const onImageLoad = () => {
  imageLoaded.value = true;
  updateContainerDimensions();
  thumbnail.value = initializeThumbnail();
};

const thumbnailStyle = computed(() => {
  // Calculate pixel positions from percentages
  const topPx = thumbnail.value.top * containerHeight.value;
  const leftPx = thumbnail.value.left * containerWidth.value;

  // Calculate the square size in pixels from uniform size
  const sizePx = calculateSquareSize(thumbnail.value.width);

  return {
    position: "absolute",
    top: `${topPx}px`,
    left: `${leftPx}px`,
    width: `${sizePx}px`,
    height: `${sizePx}px`,
    border: "2px solid white",
    boxShadow: "0 0 0 9999px rgba(0, 0, 0, 0.5)",
    cursor: isDragging.value ? "grabbing" : "grab",
    boxSizing: "border-box",
  };
});

const onDragStart = (event) => {
  if (isResizing.value) return;

  isDragging.value = true;
  dragStartX.value = event.clientX;
  dragStartY.value = event.clientY;
  startThumbnail.value = { ...thumbnail.value };

  event.preventDefault();
};

const onResizeStart = (event) => {
  isResizing.value = true;
  dragStartX.value = event.clientX;
  dragStartY.value = event.clientY;
  startThumbnail.value = { ...thumbnail.value };

  event.preventDefault();
};

const onMouseMove = (event) => {
  if (!isDragging.value && !isResizing.value) return;

  // Calculate delta in pixels and convert to percentage
  const deltaXPx = event.clientX - dragStartX.value;
  const deltaYPx = event.clientY - dragStartY.value;
  const deltaX = deltaXPx / containerWidth.value;
  const deltaY = deltaYPx / containerHeight.value;

  if (isDragging.value) {
    handleDrag(deltaX, deltaY);
  } else if (isResizing.value) {
    handleResize(deltaXPx, deltaYPx);
  }
};

const onMouseUp = () => {
  isDragging.value = false;
  isResizing.value = false;
};

const saveThumbnail = () => {
  // Calculate the square size in pixels from uniform size
  const squareSizePx = calculateSquareSize(thumbnail.value.width);

  // Convert to dimension-specific percentages for storage
  // (These will differ on non-square images to represent the same square)
  const widthPercent = squareSizePx / containerWidth.value;
  const heightPercent = squareSizePx / containerHeight.value;

  const thumbnailData = {
    top: thumbnail.value.top,
    left: thumbnail.value.left,
    width: widthPercent,
    height: heightPercent,
  };

  emit("save", thumbnailData);
};

const cancelEdit = () => {
  emit("cancel");
};

onMounted(() => {
  window.addEventListener("mousemove", onMouseMove);
  window.addEventListener("mouseup", onMouseUp);
  window.addEventListener("resize", updateContainerDimensions);
});

onBeforeUnmount(() => {
  window.removeEventListener("mousemove", onMouseMove);
  window.removeEventListener("mouseup", onMouseUp);
  window.removeEventListener("resize", updateContainerDimensions);
});

watch(
  () => props.editMode,
  (newVal) => {
    if (newVal && image.value && image.value.complete) {
      onImageLoad();
    }
  },
);
</script>

<style scoped>
.thumbnail-editor {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.9);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  overflow: auto;
}

.editor-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  align-items: center;
}

.image-wrapper {
  max-width: 90vw;
  max-height: calc(90vh - 100px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-container {
  position: relative;
  display: inline-block;
  line-height: 0;
}

.image-container img {
  display: block;
  max-width: 90vw;
  max-height: calc(90vh - 100px);
  width: auto;
  height: auto;
  user-select: none;
  -webkit-user-drag: none;
}

.thumbnail-box {
  pointer-events: all;
}

.resize-handle {
  position: absolute;
  bottom: -8px;
  right: -8px;
  width: 16px;
  height: 16px;
  background: white;
  border: 2px solid #333;
  cursor: nwse-resize;
  border-radius: 50%;
  z-index: 10;
}

.editor-controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  background: rgba(0, 0, 0, 0.8);
  padding: 1rem;
  border-radius: 4px;
}
</style>
