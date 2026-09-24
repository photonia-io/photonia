<template>
  <div class="message is-smallish">
    <div class="message-header">
      <slot name="header"></slot>
    </div>
    <div class="message-body">
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
.message p {
  display: block;
}
.message.is-smallish {
  font-size: 0.9rem;
}
.message-body {
  padding: 1em 1em;
}
</style>
