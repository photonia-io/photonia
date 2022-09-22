<template>
  <div
    class="label"
    :style="'\
      top: ' + labelInstance.boundingBox.top * 100 + '%; \
      left: ' + labelInstance.boundingBox.left * 100 + '%; \
      width: ' + labelInstance.boundingBox.width * 100 + '%; \
      height: ' + labelInstance.boundingBox.height * 100 + '%;'
    "
  >
    <p>{{ labelInstance.name }}</p>
  </div>
</template>

<script>
export default {
  name: 'LabelInstance',
  props: [ 'labelInstance' ]
}
</script>

<style>

</style>
