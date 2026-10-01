<template>
  <SectionRow title="Latest comments" :grid="false">
    <article v-for="comment in comments" :key="comment.id" class="media">
      <figure class="media-left">
        <router-link :to="targetRoute(comment)" class="image is-48x48">
          <img v-if="thumbnail(comment)" :src="thumbnail(comment)" :alt="targetTitle(comment)" />
        </router-link>
      </figure>
      <div class="media-content">
        <p class="is-size-7 has-text-grey">
          <strong>{{ comment.authorName }}</strong> on
          <router-link :to="targetRoute(comment)">{{ targetTitle(comment) }}</router-link>
          &middot; {{ timeAgo(comment.createdAt) }}
        </p>
        <p>{{ comment.snippet }}</p>
      </div>
    </article>
  </SectionRow>
</template>

<script setup>
import SectionRow from "./section-row.vue";

defineProps({
  comments: { type: Array, required: true },
});

const targetTitle = (comment) => (comment.photo || comment.album).title;

const highlight = (comment) => ({ highlightComment: comment.id });

const targetRoute = (comment) =>
  comment.photo
    ? { name: "photos-show", params: { id: comment.photo.id }, query: highlight(comment) }
    : { name: "albums-show", params: { id: comment.album.id }, query: highlight(comment) };

const thumbnail = (comment) =>
  comment.photo
    ? comment.photo.intelligentOrSquareMediumImageUrl
    : comment.album.coverPhoto?.intelligentOrSquareMediumImageUrl;

const UNITS = [
  ["year", 365 * 24 * 3600],
  ["month", 30 * 24 * 3600],
  ["day", 24 * 3600],
  ["hour", 3600],
  ["minute", 60],
];
const relative = new Intl.RelativeTimeFormat("en", { numeric: "auto" });

const timeAgo = (iso) => {
  const seconds = (new Date(iso).getTime() - Date.now()) / 1000;
  const [unit, size] = UNITS.find(([, size]) => Math.abs(seconds) >= size) ?? UNITS.at(-1);

  return relative.format(Math.round(seconds / size), unit);
};
</script>

<style scoped>
.media img {
  object-fit: cover;
  width: 100%;
  height: 100%;
  border-radius: 0.3rem;
}
</style>
