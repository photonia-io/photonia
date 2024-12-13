<template>
  <h1
    v-if="!editing"
    class="title level-item mb-0 is-flex-grow-1 is-justify-content-flex-start"
    @click="startEditing"
  >
    <div class="editable">
      {{ title }}
    </div>
  </h1>
  <div v-else class="field is-grouped level-item is-flex-grow-1">
    <p class="control is-expanded">
      <input
        v-model="localTitle"
        class="input"
        type="text"
        placeholder="Enter a title for this photo"
        ref="input"
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
import { computed, ref, toRefs, watch, nextTick } from "vue";
import { useApplicationStore } from "../stores/application";
import { storeToRefs } from "pinia";
import toaster from "../mixins/toaster";
import titleHelper from "../mixins/title-helper";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const { photo } = toRefs(props);

const title = computed(() => titleHelper(photo));

const emit = defineEmits(["updateTitle"]);

const applicationStore = useApplicationStore();
const { editing: storeEditing } = storeToRefs(applicationStore);

const editing = ref(false);
const localTitle = ref(photo.value.title);
const input = ref(null);
var savedTitle = "";

watch(photo, (newPhoto) => {
  localTitle.value = newPhoto.title;
});

watch(storeEditing, (newEditing) => {
  if (!newEditing) {
    editing.value = false;
  }
});

const focusInput = () => {
  nextTick(() => {
    input.value.focus();
  });
};

const startEditing = () => {
  savedTitle = localTitle.value;
  editing.value = true;
  applicationStore.startEditing();
  focusInput();
};

const cancelEditing = () => {
  localTitle.value = savedTitle;
  editing.value = false;
  applicationStore.stopEditing();
};

const updateTitle = () => {
  if (savedTitle != localTitle.value) {
    if (
      localTitle.value.trim() === "" &&
      photo.value.description.trim() === ""
    ) {
      toaster("Either title or description is required", "is-warning");
      focusInput();
      return;
    }
    emit("updateTitle", { id: photo.value.id, title: localTitle.value });
  }
  editing.value = false;
  applicationStore.stopEditing();
};
</script>

<style scoped>
.editable {
  flex-grow: 1;
}
</style>
