<template>
  <PhotoInfobox>
    <template #header>Comments</template>
    <div
      v-if="loading == false && photo?.comments.length > 0"
      v-for="comment in photo.comments"
      :key="comment.id"
    >
      <div class="media mb-4">
        <div class="media-left">
          <figure class="image is-48x48">
            <img :src="buddyIconUrl(comment)" :alt="displayName(comment)" />
          </figure>
        </div>
        <div class="media-content">
          <a
            :href="comment.flickrUser.profileurl"
            target="_blank"
            class="flickr-link"
          >
            <img
              src="@/assets/flickr-icon-64x64.png"
              alt="Flickr User"
              class="flickr-icon mr-2"
            />
            <strong>{{ displayName(comment) }}</strong>
          </a>
          <small class="ml-2">{{ momentFormat(comment.createdAt) }}</small>
          <small class="ml-2" v-if="comment.bodyEdited"><em>Edited</em></small>
          <div v-html="marked.parse(comment.body)"></div>
        </div>
      </div>
    </div>
    <div v-else>
      <em
        >There are no comments for this photo. You'll soon be able to add your
        own. ;-)</em
      >
    </div>
  </PhotoInfobox>
</template>

<script setup>
import { marked } from "marked";
import moment from "moment/min/moment-with-locales";

// components
import PhotoInfobox from "./photo-infobox.vue";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    required: true,
  },
});

function displayName(comment) {
  return (
    comment.flickrUser.realname ||
    comment.flickrUser.username ||
    comment.flickrUser.nsid
  );
}

function buddyIconUrl(comment) {
  if (comment.flickrUser.iconfarm != null) {
    return `http://farm${comment.flickrUser.iconfarm}.staticflickr.com/${comment.flickrUser.iconserver}/buddyicons/${comment.flickrUser.nsid}.jpg`;
  } else {
    return "https://www.flickr.com/images/buddyicon.gif";
  }
}

const format = "dddd, MMMM Do YYYY, H:mm";
function momentFormat(date) {
  return moment(date).format(format);
}
</script>

<style scoped>
.flickr-icon {
  width: 1.5em;
  height: 1.5em;
  vertical-align: top;
}

.flickr-link {
  color: #3c6cce !important;
  text-decoration: none !important;
}
</style>
