<template>
  <div class="message is-smallish">
    <div
      class="message-header"
      :class="{
        'is-collapsible': collapsible,
        'is-collapsed': collapsible && !expanded,
      }"
      :role="collapsible ? 'button' : undefined"
      :tabindex="collapsible ? 0 : undefined"
      :aria-expanded="collapsible ? expanded : undefined"
      @click="collapsible && toggle()"
      @keydown.enter="handleKeydown"
      @keydown.space="handleKeydown"
    >
      <slot name="header"></slot>
      <span v-if="collapsible" class="icon infobox-toggle" :class="{ 'is-collapsed': !expanded }">
        <i class="fas fa-chevron-down" aria-hidden="true"></i>
      </span>
    </div>
    <div class="message-body" v-show="!collapsible || expanded">
      <slot></slot>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";

const props = defineProps({
  collapsible: {
    type: Boolean,
    default: false,
  },
  defaultOpen: {
    type: Boolean,
    default: true,
  },
});

const expanded = ref(props.defaultOpen);

const toggle = () => {
  expanded.value = !expanded.value;
};

// .prevent alone would swallow Enter/Space on a header-slot element even
// when not collapsible, since it fires before this check does.
const handleKeydown = (event) => {
  if (!props.collapsible) return;
  event.preventDefault();
  toggle();
};
</script>

<style scoped>
.message p {
  display: block;
}
.message.is-smallish {
  font-size: 0.9rem;
}
/* Quieter than Bulma's default message: a dark, inverted-text header reads
   as an alert banner, which this isn't - but still visible against the
   body, not washed out to near-nothing. */
.message-header {
  background-color: var(--bulma-scheme-main-ter);
  border-bottom: 1px solid var(--bulma-border);
  color: var(--bulma-text);
  padding: 0.5em 0.75em;
}
.message-body {
  padding: 0.75em 1em;
}
.message-header.is-collapsible {
  cursor: pointer;
  user-select: none;
}
/* Collapsed, the header is the whole visible box - round its bottom to
   match the message container instead of leaving it square. */
.message-header.is-collapsed {
  border-end-start-radius: var(--bulma-message-radius, var(--bulma-radius));
  border-end-end-radius: var(--bulma-message-radius, var(--bulma-radius));
}
.infobox-toggle {
  transition: transform 0.15s ease;
}
.infobox-toggle.is-collapsed {
  transform: rotate(-90deg);
}
</style>
