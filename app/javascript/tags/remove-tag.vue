<template>
  <a class="tag is-delete is-danger" title="Delete tag" @click="modalActive = true"></a>
  <teleport to="#modal-root">
    <div :class="['modal', modalActive ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Remove Tag</p>
        </header>
        <div class="modal-card-body">
          <p>
            Are you sure you want to remove the tag "{{ props.tag.name }}" from this photo?
          </p>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-danger" @click="performDelete" :disabled="loading">
            Remove
          </button>
          <button class="button is-info" @click="modalActive = false" :disabled="loading">
            Cancel
          </button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import gql from "graphql-tag";

const props = defineProps({
  tag: {
    type: Object,
    required: true,
  },
  photoId: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["tagRemoved"]);

const modalActive = ref(false);
const loading = ref(false);

const REMOVE_TAG_FROM_PHOTO = gql`
  mutation RemoveTagFromPhoto($id: String!, $tagName: String!) {
    removeTagFromPhoto(id: $id, tagName: $tagName) {
      photo {
        id
        tagList
      }
      tag {
        id
        name
      }
    }
  }
`;

const { mutate: removeTagFromPhoto } = useMutation(REMOVE_TAG_FROM_PHOTO);

const performDelete = async () => {
  loading.value = true;
  try {
    const result = await removeTagFromPhoto({
      id: props.photoId,
      tagName: props.tag.name,
    });
    
    if (result?.data?.removeTagFromPhoto) {
      emit("tagRemoved", {
        photo: result.data.removeTagFromPhoto.photo,
        tag: result.data.removeTagFromPhoto.tag,
      });
      modalActive.value = false;
    }
  } catch (error) {
    console.error("Error removing tag:", error);
    // You might want to show an error message to the user here
  } finally {
    loading.value = false;
  }
};
</script>
