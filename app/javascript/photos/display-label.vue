<template>
  <Transition name="fade">
    <div
      v-if="highlighted"
      class="label"
      :style="`
        top: ${label.boundingBox.top * 100}%;
        left: ${label.boundingBox.left * 100}%;
        width: ${label.boundingBox.width * 100}%;
        height: ${label.boundingBox.height * 100}%;
      `"
    >
      <p>{{ label.name }}</p>
    </div>
  </Transition>
</template>

<script setup>
const props = defineProps({
  label: {
    type: Object,
    required: true,
  },
  highlighted: {
    type: Boolean,
    required: false,
  },
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
.fade-enter-to,
.fade-leave-from {
  opacity: 1;
}

.label {
  border: 1px solid black;
  position: absolute;
  outline: 1px solid rgba(255, 255, 255, 0.9);
  z-index: 30;
}
.label > p {
  position: absolute;
  font-size: 10px;
  background: rgba(255, 255, 255, 0.9);
  padding: 4px;
  margin: -26px 0 0 0;
  white-space: nowrap;
  min-width: 100%;
  outline: 2px solid rgba(255, 255, 255, 0.9);
}
</style>
