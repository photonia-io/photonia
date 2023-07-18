<template>
  <div v-if="!editing" class="content" @click="startEditing">
    {{ localDescription }}
  </div>
  <div v-else class="field is-grouped level-item is-flex-grow-1">
    <p class="control is-expanded">
      <input
        v-model="localDescription"
        class="input"
        type="text"
        placeholder="Enter a description for this photo"
      />
    </p>
    <p class="control">
      <button class="button is-info" @click="updateDescription">Save</button>
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
  description: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["updateDescription"]);

const applicationStore = useApplicationStore();

const editing = ref(false);
const localDescription = ref(props.description);
var savedDescription = "";

watch(toRef(props, "description"), (newDescription) => {
  localDescription.value = newDescription;
});

const startEditing = () => {
  savedDescription = localDescription.value;
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

<style scoped>
/* [contenteditable="true"]:focus {
    background: green;
    min-width: 50%;
  } */
</style>
