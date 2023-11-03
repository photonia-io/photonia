<template>
  <div
    class="label"
    :style="
      '\
      top: ' +
      label.boundingBox.top * 100 +
      '%; \
      left: ' +
      label.boundingBox.left * 100 +
      '%; \
      width: ' +
      label.boundingBox.width * 100 +
      '%; \
      height: ' +
      label.boundingBox.height * 100 +
      '%;'
    "
  >
    <p>{{ label.name }}</p>
  </div>
</template>

<script setup>
import { ref, toRef, watch } from "vue";

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

const opacity = ref(0);
watch(toRef(props, "highlighted"), (newHighlighted) => {
  opacity.value = newHighlighted ? 1 : 0;
});
</script>

<style scoped>
.label {
  cursor: pointer;
  border: 1px solid black;
  position: absolute;
  outline: 1px solid rgba(255, 255, 255, 0.9);
  position: absolute;
  transition: 0.3s;
  opacity: v-bind(opacity);
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
