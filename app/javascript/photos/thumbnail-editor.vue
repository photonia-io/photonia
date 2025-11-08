<template>
  <div class="thumbnail-editor" v-if="editMode">
    <div class="editor-container">
      <div class="image-container" ref="imageContainer">
        <img 
          ref="image" 
          :src="photo.extralargeImageUrl" 
          alt="Photo for thumbnail editing"
          @load="onImageLoad"
          style="display: block; max-width: 100%; height: auto;"
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
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';

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

const emit = defineEmits(['save', 'cancel']);

const imageContainer = ref(null);
const image = ref(null);
const imageLoaded = ref(false);

// Thumbnail bounding box in percentage (0-1)
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

const onImageLoad = () => {
  imageLoaded.value = true;
  updateContainerDimensions();
  
  // Initialize with user thumbnail or intelligent thumbnail
  if (props.photo.userThumbnail) {
    thumbnail.value = {
      top: props.photo.userThumbnail.top,
      left: props.photo.userThumbnail.left,
      width: props.photo.userThumbnail.width,
      height: props.photo.userThumbnail.height,
    };
  } else if (props.photo.intelligentThumbnail) {
    const bbox = props.photo.intelligentThumbnail.boundingBox;
    thumbnail.value = {
      top: bbox.top,
      left: bbox.left,
      width: bbox.width,
      height: bbox.height,
    };
  } else {
    // Default to center square
    thumbnail.value = {
      top: 0.25,
      left: 0.25,
      width: 0.5,
      height: 0.5,
    };
  }
};

const updateContainerDimensions = () => {
  if (image.value) {
    containerWidth.value = image.value.clientWidth;
    containerHeight.value = image.value.clientHeight;
  }
};

const thumbnailStyle = computed(() => {
  const size = Math.min(thumbnail.value.width, thumbnail.value.height);
  return {
    position: 'absolute',
    top: `${thumbnail.value.top * 100}%`,
    left: `${thumbnail.value.left * 100}%`,
    width: `${size * 100}%`,
    height: `${size * 100}%`,
    border: '2px solid white',
    boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.5)',
    cursor: isDragging.value ? 'grabbing' : 'grab',
    boxSizing: 'border-box',
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
  
  const deltaX = (event.clientX - dragStartX.value) / containerWidth.value;
  const deltaY = (event.clientY - dragStartY.value) / containerHeight.value;
  
  if (isDragging.value) {
    // Move the thumbnail
    let newLeft = startThumbnail.value.left + deltaX;
    let newTop = startThumbnail.value.top + deltaY;
    
    // Constrain to image bounds
    const size = Math.min(startThumbnail.value.width, startThumbnail.value.height);
    newLeft = Math.max(0, Math.min(1 - size, newLeft));
    newTop = Math.max(0, Math.min(1 - size, newTop));
    
    thumbnail.value.left = newLeft;
    thumbnail.value.top = newTop;
  } else if (isResizing.value) {
    // Resize the thumbnail (keeping it square)
    const delta = Math.max(deltaX, deltaY);
    let newSize = Math.min(startThumbnail.value.width, startThumbnail.value.height) + delta;
    
    // Constrain size
    const maxSize = Math.min(
      1 - startThumbnail.value.left,
      1 - startThumbnail.value.top
    );
    newSize = Math.max(0.1, Math.min(maxSize, newSize));
    
    thumbnail.value.width = newSize;
    thumbnail.value.height = newSize;
  }
};

const onMouseUp = () => {
  isDragging.value = false;
  isResizing.value = false;
};

const saveThumbnail = () => {
  // Ensure thumbnail is square
  const size = Math.min(thumbnail.value.width, thumbnail.value.height);
  const thumbnailData = {
    top: thumbnail.value.top,
    left: thumbnail.value.left,
    width: size,
    height: size,
  };
  
  emit('save', thumbnailData);
};

const cancelEdit = () => {
  emit('cancel');
};

onMounted(() => {
  window.addEventListener('mousemove', onMouseMove);
  window.addEventListener('mouseup', onMouseUp);
  window.addEventListener('resize', updateContainerDimensions);
});

onBeforeUnmount(() => {
  window.removeEventListener('mousemove', onMouseMove);
  window.removeEventListener('mouseup', onMouseUp);
  window.removeEventListener('resize', updateContainerDimensions);
});

watch(() => props.editMode, (newVal) => {
  if (newVal && image.value && image.value.complete) {
    onImageLoad();
  }
});
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
}

.editor-container {
  max-width: 90vw;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.image-container {
  position: relative;
  display: inline-block;
  max-width: 100%;
  max-height: calc(90vh - 100px);
  overflow: hidden;
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
