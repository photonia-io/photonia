<template>
  <DisplayHero
    :photo="result?.latestPhoto ?? {}"
    :loading="loading"
    :isHomepage="true"
  />
  <section class="section-pt-pb-0">
    <div class="container">
      <StatsLine v-if="enabled.stats" :stats="result?.homepageStats" />

      <SectionRow
        v-if="loading || latestPhotos.length"
        :loading="loading"
        title="More of the latest"
        :to="{ name: 'photos-index' }"
        link-label="Browse the full feed..."
      >
        <HomeTile
          v-for="photo in latestPhotos"
          :key="photo.id"
          :to="
            photo.feedAlbum
              ? { name: 'albums-show', params: { id: photo.feedAlbum.id } }
              : { name: 'photos-show', params: { id: photo.id } }
          "
          :title="photo.feedAlbum ? photo.feedAlbum.title : photo.title"
          :image-url="photo.intelligentOrSquareMediumImageUrl"
          :count="photo.feedAlbum?.photosCount"
        />
      </SectionRow>

      <SectionRow
        v-if="enabled.latest_albums && (loading || latestAlbums.length)"
        :loading="loading"
        title="Latest albums"
        :to="{ name: 'albums-index' }"
        link-label="See all albums..."
      >
        <HomeTile
          v-for="album in latestAlbums"
          :key="album.id"
          :to="{ name: 'albums-show', params: { id: album.id } }"
          :title="album.title"
          :image-url="album.coverPhoto?.intelligentOrSquareMediumImageUrl"
          :count="album.photosCount"
        />
      </SectionRow>

      <AlbumSpotlight v-if="enabled.album_spotlight" :album="spotlightAlbum" :loading="loading" />

      <RandomPhotos v-if="enabled.random" />

      <!-- Below the always-present rows: these only appear when there's a match -->
      <SectionRow v-if="onThisDay.length" title="On this day">
        <HomeTile
          v-for="photo in onThisDay"
          :key="photo.id"
          :to="{ name: 'photos-show', params: { id: photo.id } }"
          :title="photo.title"
          :subtitle="yearsAgo(photo.takenAt)"
          :image-url="photo.intelligentOrSquareMediumImageUrl"
        />
      </SectionRow>

      <SectionRow v-if="thisMonth.length" :title="`More from ${monthName}`">
        <HomeTile
          v-for="photo in thisMonth"
          :key="photo.id"
          :to="{ name: 'photos-show', params: { id: photo.id } }"
          :title="photo.title"
          :subtitle="takenYear(photo.takenAt)"
          :image-url="photo.intelligentOrSquareMediumImageUrl"
        />
      </SectionRow>

      <SectionRow v-if="popular.length" :title="popularTitle">
        <HomeTile
          v-for="photo in popular"
          :key="photo.id"
          :to="{ name: 'photos-show', params: { id: photo.id } }"
          :title="photo.title"
          :subtitle="photo.impressionsCount ? `${photo.impressionsCount.toLocaleString('en')} views` : null"
          :image-url="photo.intelligentOrSquareMediumImageUrl"
        />
      </SectionRow>

      <SectionRow v-if="hiddenGems.length" title="Hidden gems">
        <HomeTile
          v-for="photo in hiddenGems"
          :key="photo.id"
          :to="{ name: 'photos-show', params: { id: photo.id } }"
          :title="photo.title"
          :image-url="photo.intelligentOrSquareMediumImageUrl"
        />
      </SectionRow>

      <SectionRow v-if="recentlyCommented.length" title="Recently commented">
        <HomeTile
          v-for="comment in recentlyCommented"
          :key="comment.id"
          :to="commentRoute(comment)"
          :title="(comment.photo || comment.album).title"
          :subtitle="`${comment.commentsCount} ${comment.commentsCount === 1 ? 'comment' : 'comments'}`"
          :image-url="commentImage(comment)"
        />
      </SectionRow>

      <RecentComments v-if="recentComments.length" :comments="recentComments" />

      <YearLinks v-if="enabled.years && years.length" :years="years" />

      <MostUsedTags
        v-if="result && result.mostUsedTags"
        :tags="result.mostUsedTags"
      />
    </div>
  </section>
</template>

<script setup>
  import { computed } from 'vue'
  import gql from 'graphql-tag'
  import { useQuery } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'

  // components
  import DisplayHero from '../photos/display-hero.vue'
  import SectionRow from './section-row.vue'
  import HomeTile from './home-tile.vue'
  import StatsLine from './stats-line.vue'
  import AlbumSpotlight from './album-spotlight.vue'
  import RandomPhotos from './random-photos.vue'
  import YearLinks from './year-links.vue'
  import RecentComments from './recent-comments.vue'
  import MostUsedTags from './most-used-tags.vue'

  useTitle('')

  // Sections the admin has switched off (admin > Homepage) are neither shown
  // nor queried. Anything not mentioned in the settings counts as on.
  const SECTIONS = [
    'stats', 'latest_albums', 'album_spotlight', 'random', 'on_this_day', 'this_month',
    'popular', 'hidden_gems', 'recently_commented', 'recent_comments', 'years', 'tags',
  ]
  const flags = window.settings?.homepage ?? {}
  const enabled = Object.fromEntries(SECTIONS.map((section) => [section, flags[section] !== false]))

  const { result, loading } = useQuery(gql`${gql_queries.homepage_index}`, {
    latestAlbums: enabled.latest_albums,
    spotlight: enabled.album_spotlight,
    onThisDay: enabled.on_this_day,
    thisMonth: enabled.this_month,
    popular: enabled.popular,
    hiddenGems: enabled.hidden_gems,
    recentlyCommented: enabled.recently_commented,
    recentComments: enabled.recent_comments,
    stats: enabled.stats || enabled.years,
    tags: enabled.tags,
  })

  const spotlightAlbum = computed(() => result.value?.albumSpotlight ?? null)

  const latestPhotos = computed(() => result.value?.latestPhotos?.collection ?? [])
  const latestAlbums = computed(() => result.value?.latestAlbums?.collection ?? [])
  const onThisDay = computed(() => result.value?.onThisDay?.collection ?? [])
  const thisMonth = computed(() => result.value?.thisMonth?.collection ?? [])
  const hiddenGems = computed(() => result.value?.hiddenGems?.collection ?? [])

  // Trending needs a few photos to be worth a row; otherwise show all-time most viewed
  const MIN_TRENDING = 3
  const trending = computed(() => result.value?.trending?.collection ?? [])
  const trendingShown = computed(() => trending.value.length >= MIN_TRENDING)
  const popular = computed(() =>
    trendingShown.value ? trending.value : (result.value?.mostViewed?.collection ?? []),
  )
  const popularTitle = computed(() => (trendingShown.value ? 'Trending this week' : 'Most viewed'))

  const recentComments = computed(() => result.value?.recentComments ?? [])
  const recentlyCommented = computed(() => result.value?.recentlyCommented ?? [])

  const commentRoute = (comment) =>
    comment.photo
      ? { name: 'photos-show', params: { id: comment.photo.id } }
      : { name: 'albums-show', params: { id: comment.album.id } }

  const commentImage = (comment) =>
    comment.photo
      ? comment.photo.intelligentOrSquareMediumImageUrl
      : comment.album.coverPhoto?.intelligentOrSquareMediumImageUrl

  const years = computed(() => result.value?.homepageStats?.years ?? [])

  const monthName = new Date().toLocaleString('en', { month: 'long' })

  // takenAt is a local wall-clock ISO string, so its year is read as written
  const takenYear = (takenAt) => (takenAt ? takenAt.slice(0, 4) : null)

  const yearsAgo = (takenAt) => {
    if (!takenAt) return null
    const diff = new Date().getFullYear() - Number(takenAt.slice(0, 4))
    return diff === 1 ? '1 year ago' : `${diff} years ago`
  }
</script>
