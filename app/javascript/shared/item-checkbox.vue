<template>
  <div class="item-checkbox-container">
    <div
      :class="['item-checkbox', { 'checked': props.checked }]"
    >
      <div
        v-if="props.checked"
        class="item-checkmark"
      >
        &nbsp;
      </div>
    </div>
  </div>
</template>

<script setup>
  const props = defineProps({
    checked: {
      type: Boolean,
      required: true,
      default: false
    }
  })
</script>

<style>
  .item-checkbox-container {
    position: absolute;
    top: 1.25em;
    right: 0.75em;
  }

  .item-checkbox {
    display: inline-block;
    width: 1.5em;
    height: 1.5em;
    background-color: #fff;
    border-radius: 3px;
    border: 1px solid #ccc;
  }

  .item-checkbox:hover {
    border-color: #00d1b2;
  }

  .item-checkmark {
    display: inline-block;
    position: absolute;
    width: .375rem;
    height: .6rem;
    top: .4rem;
    left: .6rem;
    box-sizing: border-box;
    transform: translateY(0) rotate(45deg);
    border-width: .2rem;
    border-top-width: 0.2rem;
    border-left-width: 0.2rem;
    border-style: solid;
    border-top-style: solid;
    border-left-style: solid;
    border-color: white;
    border-top-color: white;
    border-left-color: white;
    border-top: 0;
    border-left: 0;
  }

  .item-checkbox.checked {
    background-color: #00d1b2;
    border-color: #00d1b2;
  }
</style>
