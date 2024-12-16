<template>
  <div v-if="!editing" class="content" @click="startEditing">
    <div class="editable" v-html="marked.parse(description)"></div>
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
          placeholder="Enter a description for this album"
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
import { computed, ref, toRefs, watch, nextTick } from "vue";
import { useApplicationStore } from "../stores/application";
import { storeToRefs } from "pinia";
import { marked } from "marked";
import toaster from "../mixins/toaster";
import { descriptionHelper } from "../mixins/description-helper";

const props = defineProps({
  album: {
    type: Object,
    required: true,
  },
});

const { album } = toRefs(props);

const description = computed(() => descriptionHelper(album));

const emit = defineEmits(["updateDescription"]);

const applicationStore = useApplicationStore();
const { editing: storeEditing } = storeToRefs(applicationStore);

const editing = ref(false);
const showPreview = ref(true);
const localDescription = ref(album.value.description);
const textarea = ref(null);
var savedDescription = "";

watch(album, (newAlbum) => {
  localDescription.value = newAlbum.description;
});

watch(storeEditing, (newEditing) => {
  if (!newEditing) {
    editing.value = false;
  }
});

const focusTextarea = () => {
  nextTick(() => {
    textarea.value.focus();
  });
};

const startEditing = () => {
  savedDescription = localDescription.value;
  showPreview.value = false;
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
      album.value.title.trim() === ""
    ) {
      toaster("Either title or description is required", "is-warning");
      focusTextarea();
      return;
    }
    emit("updateDescription", {
      id: album.value.id,
      description: localDescription.value,
    });
  }
  editing.value = false;
  applicationStore.stopEditing();
};
</script>
