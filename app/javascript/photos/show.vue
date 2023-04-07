<template>
  <div>
    <DisplayHero
      :photo="photo"
      :labelHighlights="labelHighlights"
    />
    <div class="container">
      <div class="level mb-4"> <!-- Photo title and navigation -->
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
      </div> <!-- End photo title and navigation -->
      <div class="block mt-2">
        <div class="columns">
          <div class="column is-three-quarters">
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

            <PhotoInfo
              :photo="photo"
              :loading="loading"
            />

            <SidebarHeader
              v-if="photo.labels?.length > 0"
              icon="far fa-square"
              title="Labels"
            />
            <div
              v-if="photo.labels?.length > 0"
              class="tags"
            >
              <SidebarLabel
                v-for="label in photo.labels"
                @highlight-label="highlightLabel"
                @un-highlight-label="unHighlightLabel"
                :label="label"
                :key="label.id"
              />
            </div>

            <SidebarHeader
              icon="fas fa-tag"
              title="Tags"
            />
            <div class="tags">
              <Tag
                v-for="tag in photo.userTags"
                :key="tag.id"
                :tag="tag"
              />
            </div>

            <SidebarHeader
              icon="fas fa-robot"
              title="Machine Tags"
            />
            <div class="tags">
              <Tag
                v-for="tag in photo.machineTags"
                :key="tag.id"
                :tag="tag"
                type="machine"
              />
            </div>
          </div>
          <div class="column is-one-quarter">
            <SidebarHeader
              v-if="showAlbumBrowser"
              icon="fas fa-book"
              title="Albums"
            />
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
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { ref, computed } from 'vue'
  import { useRoute } from 'vue-router'
  import gql from 'graphql-tag'
  import { useQuery, useMutation } from '@vue/apollo-composable'
  import { useTitle } from 'vue-page-title'
  import { useUserStore } from '../stores/user'

  // components
  import PhotoTitleEditable from './photo-title-editable.vue'
  import PhotoDescriptionEditable from './photo-description-editable.vue'
  import PhotoInfo from './photo-info.vue'
  import SmallNavigationButton from '@/photos/small-navigation-button.vue'
  import DisplayHero from './display-hero.vue'
  import SidebarHeader from './sidebar-header.vue'
  import SidebarLabel from '@/photos/sidebar-label.vue'
  import Tag from '@/tags/tag.vue'
  import Empty from '@/empty.vue'

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
          labels: null,
          intelligentThumbnail: null
        }

  const id = computed(() => route.params.id)
  const { result, loading } = useQuery(gql`${gql_queries.photos_show}`, { id: id })
  const labelHighlights = ref({})

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

  const highlightLabel = (label) => {
    labelHighlights.value[label.id] = true
  }

  const unHighlightLabel = (label) => {
    labelHighlights.value[label.id] = false
  }

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
