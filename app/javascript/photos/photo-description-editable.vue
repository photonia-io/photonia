<template>
  <div v-if="!editing" class="content" @click="startEditing">
    <div class="editable" v-html="marked.parse(description)"></div>
  </div>
  <div v-else class="mb-4">
    <MarkdownEditor
      v-model="localDescription"
      placeholder="Enter a description for this photo"
      :start-in-preview="false"
      ref="markdownEditor"
    >
      <template #actions>
        <div class="level-item">
          <div class="field is-grouped is-grouped-right">
            <p class="control">
              <button class="button is-primary" @click="updateDescription">
                Save
              </button>
            </p>
            <p class="control">
              <button class="button" @click="cancelEditing">Cancel</button>
            </p>
          </div>
        </div>
      </template>
    </MarkdownEditor>
  </div>
</template>

<script setup>
import { computed, ref, toRefs, watch } from "vue";
import { useApplicationStore } from "../stores/application";
import { storeToRefs } from "pinia";
import { marked } from "marked";
import toaster from "../mixins/toaster";
import { descriptionHelper } from "../mixins/description-helper";
import MarkdownEditor from "../shared/markdown-editor.vue";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const { photo } = toRefs(props);

const description = computed(() => descriptionHelper(photo));

const emit = defineEmits(["updateDescription"]);

const applicationStore = useApplicationStore();
const { editing: storeEditing } = storeToRefs(applicationStore);

const editing = ref(false);
const localDescription = ref(photo.value.description);
const markdownEditor = ref(null);
var savedDescription = "";

watch(photo, (newPhoto) => {
  localDescription.value = newPhoto.description;
});

watch(storeEditing, (newEditing) => {
  if (!newEditing) {
    editing.value = false;
  }
});

const focusTextarea = () => {
  if (markdownEditor.value) {
    markdownEditor.value.focusTextarea();
  }
};

const startEditing = () => {
  savedDescription = localDescription.value;
  editing.value = true;
  applicationStore.startEditing();
  focusTextarea();
};

const cancelEditing = () => {
  localDescription.value = savedDescription;
  editing.value = false;
  applicationStore.stopEditing();
};

const updateDescription = () => {
  if (savedDescription != localDescription.value) {
    if (
      localDescription.value.trim() === "" &&
      photo.value.title.trim() === ""
    ) {
      toaster("Either title or description is required", "is-warning");
      focusTextarea();
      return;
    }
    emit("updateDescription", {
      id: photo.value.id,
      description: localDescription.value,
    });
  }
  editing.value = false;
  applicationStore.stopEditing();
};
</script>

