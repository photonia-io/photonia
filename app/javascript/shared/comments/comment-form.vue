<template>
  <div class="comment-form">
    <MarkdownEditor
      v-model="draft"
      :placeholder="placeholder"
      :start-in-preview="false"
      ref="markdownEditor"
    >
      <template #actions>
        <div class="level-item">
          <div class="field is-grouped is-grouped-right">
            <p class="control">
              <button
                class="button is-primary"
                :class="{ 'is-loading': busy }"
                :disabled="busy || !draft.trim()"
                @click="submit"
              >
                {{ submitLabel }}
              </button>
            </p>
            <p class="control" v-if="showCancel">
              <button class="button" :disabled="busy" @click="cancel">
                Cancel
              </button>
            </p>
          </div>
        </div>
      </template>
    </MarkdownEditor>
  </div>
</template>

<script setup>
import { ref, watch, onBeforeUnmount } from "vue";
import { useApplicationStore } from "@/stores/application";
import MarkdownEditor from "@/shared/markdown-editor.vue";

const props = defineProps({
  initialBody: {
    type: String,
    default: "",
  },
  placeholder: {
    type: String,
    default: "Write a comment...",
  },
  submitLabel: {
    type: String,
    default: "Post",
  },
  showCancel: {
    type: Boolean,
    default: false,
  },
  busy: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["submit", "cancel"]);

const applicationStore = useApplicationStore();
const draft = ref(props.initialBody);

// Blocks navigation and disables J/K/arrow shortcuts while there's an
// unsaved draft, same guard the photo/album title and description editors use.
if (draft.value.trim()) applicationStore.startEditing();

watch(draft, (value) => {
  if (value.trim()) {
    applicationStore.startEditing();
  } else {
    applicationStore.stopEditing();
  }
});

const submit = () => {
  if (!draft.value.trim() || props.busy) return;
  emit("submit", draft.value);
};

const cancel = () => {
  applicationStore.stopEditing();
  emit("cancel");
};

onBeforeUnmount(() => {
  applicationStore.stopEditing();
});
</script>
