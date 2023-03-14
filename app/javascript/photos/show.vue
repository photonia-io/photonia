<template>
  <div>
    <div class="level mb-4">
      <div class="level-left is-flex-grow-1" id="photo-title-container">
        <PhotoTitleEditable
          v-if="(userStore.signedIn && !loading)"
          :id="photo.id"
          :title="photoTitle()"
          @update-title="updatePhotoTitle"
        />
        <h1
          v-else
          class="title level-item"
        >
          {{ photoTitle() }}
        </h1>
      </div>
      <div class="level-right">
        <SmallNavigationButton
          v-if="photo.previousPhoto"
          :photo="photo.previousPhoto"
          :loading="loading"
          direction="left"
        />
        <SmallNavigationButton
          v-if="photo.nextPhoto"
          :photo="photo.nextPhoto"
          :loading="loading"
          direction="right"
        />
      </div>
    </div>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div class="columns is-1">
      <div class="column is-three-quarters">
        <Display :photo="photo" />
        <h2 class="heading">Description</h2>
        <PhotoDescriptionEditable
          v-if="(userStore.signedIn && !loading)"
          :id="photo.id"
          :description="photoDescription()"
          @update-description="updatePhotoDescription"
        />
        <div
          v-else
          class="content"
        >
          {{ photoDescription() }}
        </div>
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
        <p v-if="!loading" class="content">{{ momentFormat(photo.dateTaken) }}</p>

        <h3 class="heading"><span class="icon"><i class="fas fa-arrow-circle-up"></i></span> Date Posted</h3>
        <p v-if="!loading" class="content">{{ momentFormat(photo.importedAt) }}</p>

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

<script setup>
  import { computed } from 'vue'
  import { useRoute } from 'vue-router'
  import gql from 'graphql-tag'
  import { useQuery, useMutation } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'
  import moment from 'moment'
  import { useUserStore } from '../stores/user'

  // components
  import PhotoTitleEditable from './photo-title-editable.vue'
  import PhotoDescriptionEditable from './photo-description-editable.vue'
  import SmallNavigationButton from './small-navigation-button.vue'
  import Display from './display.vue'
  import Tag from '../tags/tag.vue'
  import Empty from '../empty.vue'

  // route
  const route = useRoute()

  const emptyPhoto = {
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

  const format = 'dddd, MMMM Do YYYY, H:mm'
  function momentFormat(date) {
    return moment(date).format(format)
  }

  const id = computed(() => route.params.id)
  const { result, loading } = useQuery(gql`${gql_queries.photos_show}`, { id: id })

  const { mutate: updatePhotoTitle, onDone: onUpdateTitleDone, onError: onUpdateTitleError } = useMutation(
    gql`
      mutation($id: String!, $title: String!) {
        updatePhotoTitle(id: $id, title: $title) {
          id
          name
        }
      }
    `
  )

  const { mutate: updatePhotoDescription, onDone: onUpdateDescriptionDone, onError: onUpdateDescriptionError } = useMutation(
    gql`
      mutation($id: String!, $description: String!) {
        updatePhotoDescription(id: $id, description: $description) {
          id
          description
        }
      }
    `
  )

  onUpdateTitleDone(({ data }) => {
    console.log(data)  
  })

  onUpdateTitleError((error) => {
    // todo console.log(error)
  })

  onUpdateDescriptionDone(({ data }) => {
    console.log(data)  
  })

  onUpdateDescriptionError((error) => {
    // todo console.log(error)
  })

  const photo = computed(() => result.value?.photo ?? emptyPhoto)
  const showAlbumBrowser = computed(() => photo.value.albums.length > 0)

  const noTitle = '(no title)'
  const photoTitle = (() => loading.value ? 'Loading...' : (photo.value.name || noTitle))

  const noDescription = '(no description)'
  const photoDescription = (() => loading.value ? 'Loading...' : (photo.value.description || noDescription))

  const title = computed(() => photoTitle())
  useTitle(title)

  const userStore = useUserStore()
</script>
