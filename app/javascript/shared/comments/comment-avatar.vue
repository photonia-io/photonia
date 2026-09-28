<template>
  <figure class="image is-48x48">
    <div class="comment-avatar" :style="{ backgroundColor: color }">
      {{ initials }}
    </div>
  </figure>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  displayName: {
    type: String,
    required: true,
  },
  seed: {
    type: [String, Number],
    default: "",
  },
});

const initials = computed(() => {
  const words = props.displayName.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return "?";
  const first = words[0][0] || "";
  const second = words.length > 1 ? words[1][0] : "";
  return (first + second).toUpperCase();
});

// A stable per-author color, hashed client-side - no external avatar service.
const color = computed(() => {
  const str = String(props.seed || props.displayName);
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  const hue = Math.abs(hash) % 360;
  return `hsl(${hue}, 55%, 45%)`;
});
</script>

<style scoped>
.comment-avatar {
  width: 48px;
  height: 48px;
  border-radius: var(--bulma-radius);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 0.9rem;
}
</style>
