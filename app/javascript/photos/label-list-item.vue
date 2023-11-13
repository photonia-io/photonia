<template>
  <div
    :class="[
      'tag has-background-grey-lighter',
      { 'label-list-item-hoverable': hoverable },
    ]"
    @mouseover="hoverable && hovered(true)"
    @mouseout="hoverable && hovered(false)"
  >
    {{ label.name }} ({{ Math.ceil(label.confidence) }}%)
  </div>
</template>

<script setup>
const props = defineProps({
  label: {
    type: Object,
    required: true,
  },
  hoverable: {
    type: Boolean,
    required: false,
    default: false,
  },
});

const emit = defineEmits(["highlightLabel", "unHighlightLabel"]);

const hovered = (state) => {
  if (state) {
    emit("highlightLabel", props.label);
  } else {
    emit("unHighlightLabel", props.label);
  }
};
</script>

<style scoped>
.label-list-item-hoverable {
  cursor: pointer;
}
</style>
