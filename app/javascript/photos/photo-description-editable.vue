<template>
  <div v-if="!editing" class="content" @click="startEditing">
    <div class="editable" v-html="marked.parse(localDescription)"></div>
  </div>
  <div v-else class="mb-4">
    <div
      class="content"
      v-if="showPreview"
      v-html="marked.parse(localDescription)"
    ></div>
    <div v-else class="field">
      <div class="control is-expanded">
        <textarea
          v-model="localDescription"
          class="textarea"
          placeholder="Enter a description for this photo"
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
          <!-- <span class="icon-text">
            <span class="icon mr-1">
              <i class="fab fa-markdown"></i>
            </span>
            <span>Markdown is enabled</span>
          </span> -->
        </div>
      </div>
      <div class="level-right">
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
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, toRef, watch } from "vue";
import { useApplicationStore } from "../stores/application";
import { marked } from "marked";

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["updateDescription"]);

const applicationStore = useApplicationStore();

const editing = ref(false);
const showPreview = ref(true);
const localDescription = ref(props.description);
var savedDescription = "";

watch(toRef(props, "description"), (newDescription) => {
  localDescription.value = newDescription;
});

const startEditing = () => {
  savedDescription = localDescription.value;
  showPreview.value = false;
  editing.value = true;
  applicationStore.disableNavigationShortcuts();
};

const cancelEditing = () => {
  localDescription.value = savedDescription;
  editing.value = false;
  applicationStore.enableNavigationShortcuts();
};

const updateDescription = () => {
  if (savedDescription != localDescription.value) {
    emit("updateDescription", {
      id: props.id,
      description: localDescription.value,
    });
  }
  editing.value = false;
  applicationStore.enableNavigationShortcuts();
};
</script>
