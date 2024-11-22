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
import toaster from "../mixins/toaster";
import photoTitle from "../mixins/photo-title";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const { photo } = toRefs(props);

const title = computed(() => photoTitle(photo));

const emit = defineEmits(["updateTitle"]);

const applicationStore = useApplicationStore();

const editing = ref(false);
const localTitle = ref(photo.value.title);
const input = ref(null);
var savedTitle = "";

watch(photo, (newPhoto) => {
  localTitle.value = newPhoto.title;
});

const focusInput = () => {
  nextTick(() => {
    input.value.focus();
  });
};

const startEditing = () => {
  savedTitle = localTitle.value;
  editing.value = true;
  applicationStore.disableNavigationShortcuts();
  focusInput();
};

const cancelEditing = () => {
  localTitle.value = savedTitle;
  editing.value = false;
  applicationStore.enableNavigationShortcuts();
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
  applicationStore.enableNavigationShortcuts();
};
</script>

<style scoped>
.editable {
  flex-grow: 1;
}
</style>
