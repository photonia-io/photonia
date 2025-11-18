<template>
  <teleport to="#modal-root">
    <div :class="['modal', isActive ? 'is-active' : null]">
      <div class="modal-background" @click="close"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">Share Album</p>
          <button
            class="delete"
            aria-label="close"
            @click="close"
          ></button>
        </header>
        <div class="modal-card-body">
          <!-- Invite form -->
          <div class="field">
            <label class="label" for="share-email">Email Address</label>
            <div class="field has-addons">
              <div class="control is-expanded">
                <input
                  id="share-email"
                  class="input"
                  type="email"
                  v-model="emailInput"
                  placeholder="user@example.com"
                  @keyup.enter="inviteUser"
                />
              </div>
              <div class="control">
                <button
                  class="button is-primary"
                  @click="inviteUser"
                  :disabled="!emailInput || isInviting"
                  :class="{ 'is-loading': isInviting }"
                >
                  Invite
                </button>
              </div>
            </div>
            <p class="help" v-if="inviteError" style="color: #f14668">
              {{ inviteError }}
            </p>
            <p class="help" v-if="inviteSuccess" style="color: #48c78e">
              {{ inviteSuccess }}
            </p>
          </div>

          <!-- Current shares list -->
          <div class="mt-5" v-if="shares && shares.length > 0">
            <label class="label">Current Shares</label>
            <div class="box" v-for="share in shares" :key="share.id">
              <div class="is-flex is-justify-content-space-between is-align-items-center">
                <div>
                  <p class="has-text-weight-semibold">{{ share.email }}</p>
                  <p class="is-size-7 has-text-grey">
                    <span v-if="share.isRegisteredUser">Registered user</span>
                    <span v-else>
                      Visitor link:
                      <a
                        :href="getFullUrl(share.visitorUrl)"
                        target="_blank"
                        class="has-text-link"
                      >
                        {{ getFullUrl(share.visitorUrl) }}
                      </a>
                      <button
                        class="button is-small is-text ml-2"
                        @click="copyToClipboard(share.visitorUrl)"
                        title="Copy link"
                      >
                        📋 Copy
                      </button>
                    </span>
                  </p>
                </div>
                <button
                  class="button is-small is-danger is-outlined"
                  @click="removeShare(share.id)"
                  :disabled="isDeletingShare[share.id]"
                  :class="{ 'is-loading': isDeletingShare[share.id] }"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
          <div class="mt-5" v-else>
            <p class="has-text-grey-light">
              No one has access to this album yet. Enter an email above to invite someone.
            </p>
          </div>
        </div>
        <footer class="modal-card-foot is-justify-content-flex-end">
          <button class="button" @click="close">Close</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref, watch } from "vue";
import { useMutation } from "@vue/apollo-composable";
import gql from "graphql-tag";

const props = defineProps({
  isActive: {
    type: Boolean,
    required: true,
  },
  albumId: {
    type: String,
    required: true,
  },
  shares: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(["close", "shareCreated", "shareDeleted"]);

const emailInput = ref("");
const inviteError = ref("");
const inviteSuccess = ref("");
const isInviting = ref(false);
const isDeletingShare = ref({});

// GraphQL mutations
const CREATE_ALBUM_SHARE_MUTATION = gql`
  mutation CreateAlbumShare($albumId: String!, $email: String!) {
    createAlbumShare(albumId: $albumId, email: $email) {
      id
      email
      isRegisteredUser
      visitorUrl
      createdAt
    }
  }
`;

const DELETE_ALBUM_SHARE_MUTATION = gql`
  mutation DeleteAlbumShare($id: ID!) {
    deleteAlbumShare(id: $id) {
      success
    }
  }
`;

const { mutate: createShare } = useMutation(CREATE_ALBUM_SHARE_MUTATION);
const { mutate: deleteShare } = useMutation(DELETE_ALBUM_SHARE_MUTATION);

const close = () => {
  emit("close");
  // Reset form
  emailInput.value = "";
  inviteError.value = "";
  inviteSuccess.value = "";
};

const inviteUser = async () => {
  if (!emailInput.value) return;

  inviteError.value = "";
  inviteSuccess.value = "";
  isInviting.value = true;

  try {
    const result = await createShare({
      albumId: props.albumId,
      email: emailInput.value,
    });

    if (result.data?.createAlbumShare) {
      const share = result.data.createAlbumShare;
      inviteSuccess.value = share.isRegisteredUser
        ? `Successfully shared with ${share.email}`
        : `Visitor link created for ${share.email}`;

      emailInput.value = "";
      emit("shareCreated", share);

      // Clear success message after 3 seconds
      setTimeout(() => {
        inviteSuccess.value = "";
      }, 3000);
    }
  } catch (error) {
    inviteError.value =
      error.message || "Failed to create share. Please try again.";
  } finally {
    isInviting.value = false;
  }
};

const removeShare = async (shareId) => {
  isDeletingShare.value[shareId] = true;

  try {
    const result = await deleteShare({ id: shareId });

    if (result.data?.deleteAlbumShare?.success) {
      emit("shareDeleted", shareId);
    }
  } catch (error) {
    console.error("Failed to delete share:", error);
    inviteError.value = "Failed to remove share. Please try again.";
  } finally {
    isDeletingShare.value[shareId] = false;
  }
};

const getFullUrl = (path) => {
  if (!path) return "";
  return `${window.location.origin}${path}`;
};

const copyToClipboard = async (path) => {
  const fullUrl = getFullUrl(path);
  try {
    await navigator.clipboard.writeText(fullUrl);
    inviteSuccess.value = "Link copied to clipboard!";
    setTimeout(() => {
      inviteSuccess.value = "";
    }, 2000);
  } catch (error) {
    console.error("Failed to copy:", error);
  }
};

// Clear messages when dialog closes
watch(
  () => props.isActive,
  (newValue) => {
    if (!newValue) {
      inviteError.value = "";
      inviteSuccess.value = "";
    }
  },
);
</script>

<style scoped>
.box {
  padding: 1rem;
  margin-bottom: 0.5rem;
}

.box:last-child {
  margin-bottom: 0;
}
</style>
