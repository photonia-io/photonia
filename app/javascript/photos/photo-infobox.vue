<template>
  <div class="message is-smallish is-lightgray">
    <div class="message-header">
      <slot name="header"></slot>
    </div>
    <div class="message-body">
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
.message {
  background: none;
}
.message p {
  display: block;
}
.message.is-smallish {
  font-size: 0.9rem;
}
.message-body {
  padding: 1em 1em;
}

.message.is-lightgray .message-header {
  background-color: hsl(0, 0%, 95%);
  color: #363636;
}

.message.is-lightgray .message-body {
  background-color: hsl(0, 0%, 98%);
  color: #363636;
}
</style>
