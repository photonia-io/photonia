<template>
  <h1
    v-if="!editing"
    class="title level-item mb-0 is-flex-grow-1 is-justify-content-flex-start"
    @click="startEditing"
  >
    <div class="editable">
      Album:
      {{ title }}
    </div>
  </h1>
  <div v-else class="field is-grouped level-item is-flex-grow-1">
    <p class="control is-expanded">
      <input
        v-model="localTitle"
        class="input"
        type="text"
        placeholder="Enter a title for this album"
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
  album: {
    type: Object,
    required: true,
  },
});

const { album } = toRefs(props);

const title = computed(() => titleHelper(album));

const emit = defineEmits(["updateTitle"]);

const applicationStore = useApplicationStore();
const { editing: storeEditing } = storeToRefs(applicationStore);

const editing = ref(false);
const localTitle = ref(album.value.title);
const input = ref(null);

let savedTitle = "";

watch(album, (newAlbum) => {
  localTitle.value = newAlbum.title;
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
    if (localTitle.value.trim() === "") {
      toaster("The album title is required", "is-warning");
      focusInput();
      return;
    }
    emit("updateTitle", { id: album.value.id, title: localTitle.value });
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
