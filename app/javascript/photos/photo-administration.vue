<template>
  <div class="message is-warning">
    <div class="message-header">
      <p>Photo Administration</p>
    </div>
    <div class="message-body">
      <!-- delete photo button -->
      <button class="button is-danger" @click="deletePhoto">Delete Photo</button>
    </div>    
  </div>
</template>

<script setup>
  const emit = defineEmits(['deletePhoto'])
</script>
