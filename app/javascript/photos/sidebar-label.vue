<template>
  <div
    class="tag has-background-grey-lighter label-instance"
    @mouseover="hovered(true)"
    @mouseout="hovered(false)"
  >
    <span class="icon"><i class="far fa-square"></i></span>{{ label.name }} ({{ Math.ceil(label.confidence) }}%)
  </div>
</template>

<script setup>
  const props = defineProps({
    label: {
      type: Object,
      required: true
    }
  })

  const emit = defineEmits(['highlightLabel', 'unHighlightLabel'])

  const hovered = (state) => {
    if (state) {
      emit('highlightLabel', props.label)
    } else {
      emit('unHighlightLabel', props.label)
    }
  }
</script>

<style>
  .label-instance {
    cursor: pointer;
  }
</style>