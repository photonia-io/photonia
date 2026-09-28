<template>
  <div v-if="!loading">
    <div v-if="topLevelComments.length === 0" class="mb-4">
      <em>There are no comments yet.</em>
    </div>
    <div v-for="comment in topLevelComments" :key="comment.id" class="mb-5">
      <CommentItem
        :comment="comment"
        :can-reply="true"
        :reply-target-id="replyTargetId"
        :edit-target-id="editTargetId"
        :saving="saving"
        @start-reply="startReply"
        @cancel-reply="cancelReply"
        @submit-reply="submitReply"
        @start-edit="startEdit"
        @cancel-edit="cancelEdit"
        @submit-edit="submitEdit"
        @request-delete="requestDelete"
        @claim="openClaimModal"
      />
    </div>

    <div v-if="showNewCommentForm" class="mt-4">
      <h4 class="title is-6 mb-2">Add New Comment</h4>
      <CommentForm
        submit-label="Post Comment"
        placeholder="Write a comment..."
        :busy="saving"
        @submit="submitNewComment"
      />
    </div>
    <p v-else-if="!userStore.signedIn && commentingEnabled">
      <router-link :to="{ name: 'users-sign-in' }">Sign in</router-link> to leave a comment.
    </p>

    <!-- Delete confirmation -->
    <teleport to="#modal-root">
      <div :class="['modal', deleteModalActive ? 'is-active' : null]">
        <div class="modal-background"></div>
        <div class="modal-card" ref="deleteModalCard" tabindex="-1">
          <header class="modal-card-head">
            <p class="modal-card-title has-text-centered">Delete Comment</p>
          </header>
          <div class="modal-card-body">
            <p>
              Are you sure you want to delete this comment?
              <template v-if="commentToDelete?.replies?.length > 0">
                {{ commentToDelete.replies.length === 1 ? "Its reply" : "Its replies" }} will be deleted too.
              </template>
            </p>
          </div>
          <footer class="modal-card-foot is-justify-content-center">
            <div class="buttons">
              <button class="button is-danger" @click="performDelete">Yes, delete</button>
              <button class="button is-info" @click="closeDeleteModal">Cancel</button>
            </div>
          </footer>
        </div>
      </div>
    </teleport>

    <ClaimFlickrUserModal
      v-if="selectedFlickrUser"
      :flickr-user="selectedFlickrUser"
      :is-active="claimModalActive"
      @close="closeClaimModal"
      @claimed="handleClaimed"
    />
  </div>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import gql from "graphql-tag";
import { useMutation } from "@vue/apollo-composable";
import { useUserStore } from "@/stores/user";
import { useModal } from "@/mixins/use-modal";
import toaster from "@/mixins/toaster";
import CommentItem from "./comment-item.vue";
import CommentForm from "./comment-form.vue";
import ClaimFlickrUserModal from "@/photos/claim-flickr-user-modal.vue";

const props = defineProps({
  commentable: {
    type: Object,
    required: true,
  },
  commentableType: {
    // "Photo" or "Album"
    type: String,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["refresh"]);

const userStore = useUserStore();

const topLevelComments = computed(() => props.commentable?.comments || []);
// Read live, not via the mixins/settings.js snapshot, since that's captured
// once at module-import time - before a test can set window.settings.
const commentingEnabled = computed(() => !!window.settings?.commenting_enabled);
const canComment = computed(() => userStore.signedIn && commentingEnabled.value);

// Only one reply/edit form is open across the whole tree at a time.
const replyTargetId = ref(null);
const editTargetId = ref(null);
const saving = ref(false);

// Hide the new-comment box while a reply or edit form is open elsewhere on
// the page, so there's never more than one form visible at once.
const showNewCommentForm = computed(() => canComment.value && !replyTargetId.value && !editTargetId.value);

watch(
  () => props.commentable?.id,
  () => {
    replyTargetId.value = null;
    editTargetId.value = null;
  },
);

const startReply = (id) => {
  replyTargetId.value = id;
  editTargetId.value = null;
};
const cancelReply = () => {
  replyTargetId.value = null;
};

const startEdit = (id) => {
  editTargetId.value = id;
  replyTargetId.value = null;
};
const cancelEdit = () => {
  editTargetId.value = null;
};

const {
  mutate: createComment,
  onDone: onCreateDone,
  onError: onCreateError,
} = useMutation(gql`
  mutation (
    $commentableType: String!
    $commentableId: String!
    $body: String!
    $parentId: ID
  ) {
    createComment(
      commentableType: $commentableType
      commentableId: $commentableId
      body: $body
      parentId: $parentId
    ) {
      id
    }
  }
`);

const {
  mutate: updateComment,
  onDone: onUpdateDone,
  onError: onUpdateError,
} = useMutation(gql`
  mutation ($id: ID!, $body: String!) {
    updateComment(id: $id, body: $body) {
      id
    }
  }
`);

const {
  mutate: deleteComment,
  onDone: onDeleteDone,
  onError: onDeleteError,
} = useMutation(gql`
  mutation ($id: ID!) {
    deleteComment(id: $id) {
      id
    }
  }
`);

const submitNewComment = async (body) => {
  saving.value = true;
  await createComment({
    commentableType: props.commentableType,
    commentableId: props.commentable.id,
    body,
  });
};

const submitReply = async ({ parentId, body }) => {
  saving.value = true;
  await createComment({
    commentableType: props.commentableType,
    commentableId: props.commentable.id,
    body,
    parentId,
  });
};

const submitEdit = async ({ id, body }) => {
  saving.value = true;
  await updateComment({ id, body });
};

onCreateDone(() => {
  saving.value = false;
  replyTargetId.value = null;
  toaster("Comment posted");
  emit("refresh");
});

onCreateError((error) => {
  saving.value = false;
  toaster("An error occurred while posting the comment: " + error.message, "is-danger");
});

onUpdateDone(() => {
  saving.value = false;
  editTargetId.value = null;
  toaster("Comment updated");
  emit("refresh");
});

onUpdateError((error) => {
  saving.value = false;
  toaster("An error occurred while updating the comment: " + error.message, "is-danger");
});

onDeleteDone(() => {
  toaster("Comment deleted");
  closeDeleteModal();
  emit("refresh");
});

onDeleteError((error) => {
  toaster("An error occurred while deleting the comment: " + error.message, "is-danger");
  closeDeleteModal();
});

// Delete confirmation modal
const commentToDelete = ref(null);
const {
  active: deleteModalActive,
  modalCard: deleteModalCard,
  open: openDeleteModal,
  close: closeDeleteModal,
} = useModal();

const requestDelete = (comment) => {
  commentToDelete.value = comment;
  openDeleteModal();
};

const performDelete = () => {
  deleteComment({ id: commentToDelete.value.id });
};

// Claim Flickr user modal - unchanged from the old photo-comments.vue.
const claimModalActive = ref(false);
const selectedFlickrUser = ref(null);

const openClaimModal = (flickrUser) => {
  selectedFlickrUser.value = flickrUser;
  claimModalActive.value = true;
};
const closeClaimModal = () => {
  claimModalActive.value = false;
};
const handleClaimed = () => emit("refresh");
</script>
