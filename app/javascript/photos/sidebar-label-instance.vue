<template>
  <div
    class="tag has-background-grey-lighter label-instance"
    @mouseover="hovered(true)"
    @mouseout="hovered(false)"
  >
    <span class="icon"><i class="far fa-square"></i></span>{{ labelInstance.name }} ({{ Math.ceil(labelInstance.confidence) }}%)
  </div>
</template>

<script setup>
  const props = defineProps({
    labelInstance: {
      type: Object,
      required: true
    }
  })

  const emit = defineEmits(['highlightLabel', 'unHighlightLabel'])

  const hovered = (state) => {
    if (state) {
      emit('highlightLabel', props.labelInstance)
    } else {
      emit('unHighlightLabel', props.labelInstance)
    }
  }
</script>

<style>
  .label-instance {
    cursor: pointer;
  }
</style>