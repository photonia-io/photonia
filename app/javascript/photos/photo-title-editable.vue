<template>
  <h1 v-if="!editing" class="title level-item mb-0" @click="startEditing">
    {{ localTitle }}
  </h1>
  <div v-else class="field is-grouped level-item is-flex-grow-1">
    <p class="control is-expanded">
      <input
        v-model="localTitle"
        class="input"
        type="text"
        placeholder="Enter a title for this photo"
      />
    </p>
    <p class="control">
      <button class="button is-primary" @click="updateTitle">Save</button>
    </p>
    <p class="control">
      <button class="button" @click="cancelEditing">Cancel</button>
    </p>
  </div>
</template>

<script setup>
import { ref, toRef, watch } from "vue";
import { useApplicationStore } from "../stores/application";

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["updateTitle"]);

const applicationStore = useApplicationStore();

const editing = ref(false);
const localTitle = ref(props.title);
var savedTitle = "";

watch(toRef(props, "title"), (newTitle) => {
  localTitle.value = newTitle;
});

const startEditing = () => {
  savedTitle = localTitle.value;
  editing.value = true;
  applicationStore.disableNavigationShortcuts();
};

const cancelEditing = () => {
  localTitle.value = savedTitle;
  editing.value = false;
  applicationStore.enableNavigationShortcuts();
};

const updateTitle = () => {
  if (savedTitle != localTitle.value) {
    emit("updateTitle", { id: props.id, title: localTitle.value });
  }
  editing.value = false;
  applicationStore.enableNavigationShortcuts();
};
</script>

<style scoped>
/* [contenteditable="true"]:focus {
    background: green;
    min-width: 50%;
  } */
</style>
