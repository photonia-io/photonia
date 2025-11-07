<template>
  <div class="markdown-editor">
    <div
      class="content"
      v-if="showPreview"
      v-html="marked.parse(modelValue)"
    ></div>
    <div v-else class="field">
      <div class="control is-expanded">
        <textarea
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          class="textarea"
          :placeholder="placeholder"
          ref="textarea"
        ></textarea>
      </div>
    </div>
    <div class="level">
      <div class="level-left">
        <div class="level-item">
          <div class="field has-addons">
            <p class="control">
              <button
                class="button"
                @click="showPreview = false"
                :class="{ 'is-dark': !showPreview }"
              >
                <span class="icon is-small">
                  <i class="fas fa-edit"></i>
                </span>
                <span>Editor</span>
              </button>
            </p>
            <p class="control">
              <button
                class="button"
                @click="showPreview = true"
                :class="{ 'is-dark': showPreview }"
              >
                <span class="icon is-small">
                  <i class="fas fa-eye"></i>
                </span>
                <span>Preview</span>
              </button>
            </p>
          </div>
        </div>
        <div class="level-item" v-if="!showPreview">
          <div class="field has-addons">
            <p class="control">
              <button
                class="button"
                @click="applyFormatting('bold')"
                title="Bold"
              >
                <span class="icon is-small">
                  <i class="fas fa-bold"></i>
                </span>
              </button>
            </p>
            <p class="control">
              <button
                class="button"
                @click="applyFormatting('italic')"
                title="Italic"
              >
                <span class="icon is-small">
                  <i class="fas fa-italic"></i>
                </span>
              </button>
            </p>
          </div>
        </div>
      </div>
      <div class="level-right">
        <slot name="actions"></slot>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, nextTick } from "vue";
import { marked } from "marked";

const props = defineProps({
  modelValue: {
    type: String,
    required: true,
  },
  placeholder: {
    type: String,
    default: "Enter text here...",
  },
  startInPreview: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(["update:modelValue"]);

const showPreview = ref(props.startInPreview);
const textarea = ref(null);

watch(
  () => props.startInPreview,
  (newValue) => {
    showPreview.value = newValue;
  }
);

const focusTextarea = () => {
  nextTick(() => {
    if (textarea.value) {
      textarea.value.focus();
    }
  });
};

const applyFormatting = (type) => {
  const textareaElement = textarea.value;
  if (!textareaElement) return;

  const start = textareaElement.selectionStart;
  const end = textareaElement.selectionEnd;
  const selectedText = textareaElement.value.substring(start, end);
  const beforeText = textareaElement.value.substring(0, start);
  const afterText = textareaElement.value.substring(end);

  let formattedText = "";
  let cursorOffset = 0;

  if (type === "bold") {
    if (selectedText) {
      formattedText = `**${selectedText}**`;
      cursorOffset = 2; // Position cursor after the first **
    } else {
      formattedText = "****";
      cursorOffset = 2; // Position cursor between the asterisks
    }
  } else if (type === "italic") {
    if (selectedText) {
      formattedText = `*${selectedText}*`;
      cursorOffset = 1; // Position cursor after the first *
    } else {
      formattedText = "**";
      cursorOffset = 1; // Position cursor between the asterisks
    }
  }

  const newValue = beforeText + formattedText + afterText;
  emit("update:modelValue", newValue);

  nextTick(() => {
    const newCursorPosition = selectedText
      ? end + cursorOffset + (type === "bold" ? 2 : 1)
      : start + cursorOffset;
    textareaElement.focus();
    textareaElement.setSelectionRange(newCursorPosition, newCursorPosition);
  });
};

defineExpose({
  focusTextarea,
  showPreview,
});
</script>

<style scoped>
.markdown-editor {
  width: 100%;
}
</style>
