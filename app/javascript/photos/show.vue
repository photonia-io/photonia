<template>
  <div>
    <div class="level mb-4">
      <div class="level-left">
        <!-- <% if policy(@photo).update? %>
          <h1 id="photo-name" class="title level-item" contenteditable="true" data-photo-slug="<%= @photo.slug %>"><%= @photo.name.presence || '(no title)' %></h1>
        <% else %> -->
          <h1 class="title level-item">{{ photo.name  }}</h1>
      </div>
      <div class="level-right">
        <SmallNavigationButton
          v-if="photo.previousPhoto"
          :photo="photo.previousPhoto"
          direction="left"
        />
        <SmallNavigationButton
          v-if="photo.nextPhoto"
          :photo="photo.nextPhoto"
          direction="right"
        />
      </div>
    </div>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1">
      <div class="column is-three-quarters">
        <Display :photo="photo" />
        <!-- <% if @photo.description.presence || policy(@photo).update? %> -->
          <h2 v-if="photo.description" class="heading">Description</h2>
          <div v-if="photo.description" class="content">
            <!-- <% if policy(@photo).update? %>
              <div id="photo-description" contenteditable="true" data-photo-slug="<%= @photo.slug %>"><%= @photo.description.presence || '(no description)' %></div>
            <% else %> -->
            {{ photo.description }}
          </div>
        <!-- <% end %> -->
      </div>
      <div id="sidebar" class="column">
        <h3
          v-if="showAlbumBrowser"
          class="heading"
        >
          <span class="icon"><i class="fas fa-book"></i></span>
          Albums
        </h3>
        <ul
          v-if="showAlbumBrowser"
          class="block-list is-small has-radius pb-4"
        >
          <li
            v-for="album in photo.albums"
            :key="album.id"
          >
            <h4 class="is-size-6 mb-2">
              <router-link :to="{ name: 'albums-show', params: { id: album.id } }">
                {{ album.title }}
              </router-link>
            </h4>
            <div class="columns is-variable is-1 is-mobile">
              <div class="column is-half">
                <router-link
                  v-if="album.previousPhotoInAlbum"
                  :to="{ name: 'photos-show', params: { id: album.previousPhotoInAlbum.id } }"
                  class="button is-fullwidth is-image-button"
                >
                  <img :src="album.previousPhotoInAlbum.intelligentOrSquareThumbnailImageUrl" class="image is-fullwidth mb-2">
                  <span class="icon-text is-hidden-desktop-only is-hidden-tablet-only">
                    <span class="icon"><i class="fas fa-chevron-left"></i></span>
                    <span>Previous</span>
                  </span>
                </router-link>
                <button v-else class="button is-fullwidth is-image-button" disabled>
                  <Empty class="mb-2"/>
                  <span class="icon-text is-hidden-desktop-only is-hidden-tablet-only">
                    <span class="icon"><i class="fas fa-chevron-left"></i></span>
                    <span>Previous</span>
                  </span>
                </button>
              </div>
              <div class="column is-half">
                <router-link
                  v-if="album.nextPhotoInAlbum"
                  :to="{ name: 'photos-show', params: { id: album.nextPhotoInAlbum.id } }"
                  class="button is-fullwidth is-image-button"
                >
                  <img :src="album.nextPhotoInAlbum.intelligentOrSquareThumbnailImageUrl" class="image is-fullwidth mb-2">
                  <span class="icon-text is-hidden-desktop-only is-hidden-tablet-only">
                    <span>Next</span>
                    <span class="icon"><i class="fas fa-chevron-right"></i></span>
                  </span>
                </router-link>
                <button v-else class="button is-fullwidth is-image-button" disabled>
                  <Empty class="mb-2"/>
                  <span class="icon-text is-hidden-desktop-only is-hidden-tablet-only">
                    <span>Next</span>
                    <span class="icon"><i class="fas fa-chevron-right"></i></span>
                  </span>
                </button>
              </div>
            </div>
          </li>
        </ul>

        <h3 class="heading"><span class="icon"><i class="fas fa-camera"></i></span> Date Taken</h3>
        <p v-if="!$apollo.loading" class="content">{{ photo.dateTaken | moment("dddd, MMMM Do YYYY, H:mm:ss") }}</p>

        <h3 class="heading"><span class="icon"><i class="fas fa-arrow-circle-up"></i></span> Date Posted</h3>
        <p v-if="!$apollo.loading" class="content">{{ photo.importedAt | moment("dddd, MMMM Do YYYY, H:mm:ss") }}</p>

        <h3 class="heading"><span class="icon"><i class="fas fa-tag"></i></span> Tags</h3>
        <div class="tags">
          <Tag
            v-for="tag in photo.userTags"
            :key="tag.id"
            :tag="tag"
          />
        </div>

        <h3 class="heading"><span class="icon"><i class="fas fa-robot"></i></span> AI Tags</h3>
        <div class="tags">
          <Tag
            v-for="tag in photo.machineTags"
            :key="tag.id"
            :tag="tag"
            type="machine"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import gql from 'graphql-tag'
  import writeGQLQuery from '../mixins/write-gql-query'

  import SmallNavigationButton from './small-navigation-button.vue'
  import Display from './display.vue'
  import Tag from '../tags/tag.vue'
  import Empty from '../empty.vue'

  const queryString = gql_queries.photos_show
  const GQLQuery = gql`${queryString}`

  export default {
    name: 'PhotosShow',
    components: {
      SmallNavigationButton,
      Display,
      Tag,
      Empty
    },
    data () {
      return {
        photo: {
          name: '',
          description: '',
          largeImageUrl: '',
          previousPhoto: null,
          nextPhoto: null,
          albums: [],
          tags: [],
          rekognitionTags: [],
          labelInstances: null,
          intelligentThumbnail: null
        }
      }
    },
    computed: {
      showAlbumBrowser: function () {
        return this.photo && this.photo.albums.length > 0
      }
    },
    mixins: [writeGQLQuery(queryString, GQLQuery)],
    apollo: {
      photo: {
        query: GQLQuery,
        variables () {
          return {
            id: this.$route.params.id
          }
        }
      }
    }
  }
</script>
