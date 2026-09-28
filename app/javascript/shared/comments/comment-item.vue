<template>
  <div class="media">
    <div class="media-left">
      <figure class="image is-48x48" v-if="isFlickrAuthor">
        <img :src="buddyIconUrl" :alt="authorDisplayName" class="buddy-icon" />
      </figure>
      <CommentAvatar v-else :display-name="authorDisplayName" :seed="comment.author?.id" />
    </div>
    <div class="media-content">
      <div class="is-flex is-align-items-center is-flex-wrap-wrap">
        <a
          v-if="isFlickrAuthor"
          :href="comment.flickrUser.profileurl"
          target="_blank"
          class="flickr-link"
        >
          <img
            src="@/assets/flickr-icon-64x64.png"
            alt="Flickr User"
            class="flickr-icon mr-2"
          />
          <strong>{{ authorDisplayName }}</strong>
        </a>
        <strong v-else>{{ authorDisplayName }}</strong>
        <small class="ml-2">{{ momentFormat(comment.createdAt) }}</small>
        <small
          class="ml-2"
          v-if="comment.bodyEdited"
          title="This comment has been edited"
        >
          <em>Edited on {{ momentFormat(comment.bodyLastEditedAt) }}</em>
        </small>
        <span
          class="ml-1 claim-link"
          v-if="isFlickrAuthor && comment.flickrUser.claimable && userStore.signedIn"
        >
          -
          <a @click.prevent="$emit('claim', comment.flickrUser)" title="Claim this Flickr user">
            Claim User
          </a>
        </span>
      </div>

      <div v-if="!isEditing" class="content" v-html="comment.bodyHtml"></div>
      <CommentForm
        v-else
        :initial-body="comment.body"
        submit-label="Save"
        show-cancel
        :busy="saving"
        @submit="(body) => $emit('submit-edit', { id: comment.id, body })"
        @cancel="$emit('cancel-edit')"
      />

      <div class="comment-actions is-size-7" v-if="!isEditing">
        <a v-if="canReply" @click.prevent="toggleReply">{{ isReplying ? "Cancel" : "Reply" }}</a>
        <a v-if="comment.canEdit" @click.prevent="$emit('start-edit', comment.id)">Edit</a>
        <a v-if="comment.canDelete" @click.prevent="$emit('request-delete', comment)">Delete</a>
      </div>

      <div v-if="isReplying" class="mt-3">
        <CommentForm
          submit-label="Post Reply"
          placeholder="Write a reply..."
          show-cancel
          :busy="saving"
          @submit="(body) => $emit('submit-reply', { parentId: comment.id, body })"
          @cancel="$emit('cancel-reply')"
        />
      </div>

      <div v-if="comment.replies?.length" class="replies mt-4">
        <CommentItem
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :can-reply="false"
          :reply-target-id="replyTargetId"
          :edit-target-id="editTargetId"
          :saving="saving"
          @start-edit="$emit('start-edit', $event)"
          @cancel-edit="$emit('cancel-edit')"
          @submit-edit="$emit('submit-edit', $event)"
          @request-delete="$emit('request-delete', $event)"
          @claim="$emit('claim', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";
import moment from "moment";
import { useUserStore } from "@/stores/user";
import CommentAvatar from "./comment-avatar.vue";
import CommentForm from "./comment-form.vue";

const props = defineProps({
  comment: {
    type: Object,
    required: true,
  },
  canReply: {
    type: Boolean,
    default: false,
  },
  replyTargetId: {
    type: [String, Number],
    default: null,
  },
  editTargetId: {
    type: [String, Number],
    default: null,
  },
  saving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  "start-reply",
  "cancel-reply",
  "submit-reply",
  "start-edit",
  "cancel-edit",
  "submit-edit",
  "request-delete",
  "claim",
]);

const userStore = useUserStore();

const isFlickrAuthor = computed(() => !!props.comment.flickrUser);

// Imported comments by the site owner have both a user and a flickr_user;
// they keep the Flickr look, matching how they've always rendered.
const authorDisplayName = computed(() => {
  if (isFlickrAuthor.value) {
    const flickrUser = props.comment.flickrUser;
    return flickrUser.realname || flickrUser.username || flickrUser.nsid;
  }
  return props.comment.author?.displayName || "Deleted user";
});

const buddyIconUrl = computed(() => {
  const flickrUser = props.comment.flickrUser;
  if (flickrUser?.iconfarm != null) {
    return `http://farm${flickrUser.iconfarm}.staticflickr.com/${flickrUser.iconserver}/buddyicons/${flickrUser.nsid}.jpg`;
  }
  return "https://www.flickr.com/images/buddyicon.gif";
});

const isReplying = computed(() => props.replyTargetId === props.comment.id);
const isEditing = computed(() => props.editTargetId === props.comment.id);

const toggleReply = () => {
  if (isReplying.value) {
    emit("cancel-reply");
  } else {
    emit("start-reply", props.comment.id);
  }
};

const format = "dddd, MMMM Do YYYY, H:mm";
function momentFormat(date) {
  return moment(date).format(format);
}
</script>

<style scoped>
.buddy-icon {
  border-radius: var(--bulma-radius);
}

.flickr-icon {
  width: 1.5em;
  height: 1.5em;
  vertical-align: top;
}

.flickr-link {
  color: #3c6cce !important;
  text-decoration: none !important;
}

.claim-link a {
  cursor: pointer;
  color: #3273dc !important;
  text-decoration: none !important;
}

.comment-actions a {
  margin-right: 0.75em;
  cursor: pointer;
}

.replies {
  padding-left: 1.5em;
  border-left: 2px solid var(--bulma-border-weak);
}
</style>
