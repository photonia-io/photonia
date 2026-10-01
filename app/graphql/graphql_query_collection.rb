# frozen_string_literal: true

# This is a collection of all the GQL queries to be shared between Rails and the Vue app
class GraphqlQueryCollection
  # Shared by photos_show and albums_show below, and exposed as comment_fields
  # for the Vue mutations to reuse the same selection set.
  COMMENT_FIELDS = <<~GQL.squish
    id
    body
    bodyHtml
    bodyEdited
    bodyLastEditedAt
    createdAt
    canEdit
    canDelete
    author {
      id
      displayName
    }
    flickrUser {
      nsid
      username
      realname
      profileurl
      iconfarm
      iconserver
      claimable
    }
  GQL

  COLLECTION = {
    homepage_index: <<~GQL.squish,
      query HomepageQuery(
        $latestAlbums: Boolean!
        $spotlight: Boolean!
        $onThisDay: Boolean!
        $thisMonth: Boolean!
        $popular: Boolean!
        $hiddenGems: Boolean!
        $recentlyCommented: Boolean!
        $recentComments: Boolean!
        $stats: Boolean!
        $tags: Boolean!
      ) {
        latestPhoto: photo(fetchType: "latest") {
          id
          title
          altText
          largeImageUrl: imageUrl(type: "large")
          largeDimensions: imageDimensions(type: "large") {
            width
            height
          }
          extralargeImageUrl: imageUrl(type: "extralarge")
          extralargeDimensions: imageDimensions(type: "extralarge") {
            width
            height
          }
          feedAlbum {
            id
            title
            photosCount
          }
        }
        latestPhotos: photos(mode: "simple", fetchType: "feed", offset: 1, limit: 5) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            feedAlbum {
              id
              title
              photosCount
            }
          }
        }
        latestAlbums: albums(mode: "simple", order: "newest", limit: 5) @include(if: $latestAlbums) {
          collection {
            id
            title
            photosCount
            coverPhoto {
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
          }
        }
        albumSpotlight @include(if: $spotlight) {
          id
          title
          descriptionHtml
          photosCount
          photos {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
          }
        }
        onThisDay: photos(mode: "simple", fetchType: "on_this_day", limit: 5) @include(if: $onThisDay) {
          collection {
            id
            title
            takenAt
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        thisMonth: photos(mode: "simple", fetchType: "this_month", limit: 5) @include(if: $thisMonth) {
          collection {
            id
            title
            takenAt
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        trending: photos(mode: "simple", fetchType: "trending", limit: 5) @include(if: $popular) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        mostViewed: photos(mode: "simple", fetchType: "most_viewed", limit: 5) @include(if: $popular) {
          collection {
            id
            title
            impressionsCount
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        hiddenGems: photos(mode: "simple", fetchType: "least_viewed", limit: 5) @include(if: $hiddenGems) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        recentComments(limit: 5) @include(if: $recentComments) {
            id
            snippet
            authorName
            createdAt
            commentsCount
            photo {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
            album {
              id
              title
              coverPhoto {
                intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
              }
            }
          }
        recentlyCommented: recentComments(limit: 5, distinct: true) @include(if: $recentlyCommented) {
            id
            snippet
            authorName
            createdAt
            commentsCount
            photo {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
            album {
              id
              title
              coverPhoto {
                intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
              }
            }
          }
        homepageStats @include(if: $stats) {
          photosCount
          albumsCount
          viewsCount
          firstYear
          lastYear
          years {
            year
            count
          }
        }
        mostUsedTags: tags(type: "user", order: "most_used", limit: 15) @include(if: $tags) {
          id
          name
          taggingsCount
        }
      }
    GQL
    homepage_random_photos: <<~GQL.squish,
      query HomepageRandomPhotosQuery {
        randomPhotos: photos(mode: "simple", fetchType: "random", limit: 5) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
      }
    GQL
    albums_index: <<-GQL.squish,
      query AlbumsIndexQuery($page: Int) {
        albums(page: $page) {
          collection {
            id
            title
            photosCount
            coverPhoto {
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
      }
    GQL
    albums_show: <<-GQL.squish,
      query AlbumsShowQuery($id: ID!, $page: Int) {
        album(id: $id) {
          id
          title
          description
          descriptionHtml
          photos(page: $page) {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
              isCoverPhoto
              canEdit
            }
            metadata {
              totalPages
              totalCount
              currentPage
              limitValue
            }
          }
          sortingType
          sortingOrder
          canEdit
          privacy
          privatizablePhotosCount
          collapsedInFeed
          collapseBlocker
          comments {
            #{COMMENT_FIELDS}
            replies {
              #{COMMENT_FIELDS}
            }
          }
        }
      }
    GQL
    tags_index: <<-GQL.squish,
      query TagsIndexQuery {
        mostUsedUserTags: tags(type: "user", order: "most_used") {
          id
          name
          taggingsCount
        }
        leastUsedUserTags: tags(type: "user", order: "least_used") {
          id
          name
          taggingsCount
        }
        mostUsedMachineTags: tags(type: "machine", order: "most_used") {
          id
          name
          taggingsCount
        }
        leastUsedMachineTags: tags(type: "machine", order: "least_used") {
          id
          name
          taggingsCount
        }
      }
    GQL
    tags_show: <<-GQL.squish,
      query TagsShowQuery($id: ID!, $page: Int) {
        tag(id: $id) {
          id
          name
          relatedTags(limit: 5) {
            id
            name
          }
          photos(page: $page) {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
              canEdit
            }
            metadata {
              totalPages
              totalCount
              currentPage
              limitValue
            }
          }
        }
      }
    GQL
    photos_index: <<-GQL.squish,
      query PhotosIndexQuery($page: Int, $query: String, $hasQuery: Boolean!) {
        photos(page: $page, query: $query) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            canEdit
            feedAlbum {
              id
              title
              photosCount
            }
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
        matchingAlbums: albums(mode: "simple", query: $query, limit: 8) @include(if: $hasQuery) {
          collection {
            id
            title
            photosCount
            coverPhoto {
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
          }
        }
        matchingTags: tags(query: $query, limit: 12) @include(if: $hasQuery) {
          id
          name
        }
      }
    GQL
    photos_search: <<-GQL.squish,
      query PhotoSearchQuery($filters: PhotoSearchFiltersInput!, $sort: PhotoSortField, $direction: SortDirection, $page: Int) {
        photoSearch(filters: $filters, sort: $sort, direction: $direction, page: $page) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            canEdit
            privacy
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
        }
      }
    GQL
    photos_search_options: <<-GQL.squish,
      query PhotoSearchOptionsQuery {
        cameras {
          make
          model
          friendlyName
          count
        }
        albums(mode: "simple", limit: 200) {
          collection {
            id
            title
          }
        }
      }
    GQL
    search_suggestions: <<-GQL.squish,
      query SearchSuggestionsQuery($query: String, $limit: Int) {
        searchSuggestions(query: $query, limit: $limit) {
          searches {
            text
            count
          }
          terms {
            text
            count
          }
          photos {
            id
            title
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "thumbnail")
          }
          recent
        }
      }
    GQL
    photos_show: <<-GQL.squish,
      query PhotosShowQuery($id: ID!) {
        photo(id: $id) {
          id
          title
          altText
          description
          descriptionHtml
          largeImageUrl: imageUrl(type: "large")
          largeDimensions: imageDimensions(type: "large") {
            width
            height
          }
          extralargeImageUrl: imageUrl(type: "extralarge")
          extralargeDimensions: imageDimensions(type: "extralarge") {
            width
            height
          }
          takenAt
          license
          takenAtInfo {
            year
            month
            day
            hour
            minute
            precision
            source
            approximate
            exifAvailable
          }
          scanned
          exifExists
          exifCameraFriendlyName
          exifFNumber
          exifExposureTime
          exifFocalLength
          exifIso
          postedAt
          impressionsCount
          privacy
          previousPhoto {
            id
            title
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "thumbnail")
          }
          nextPhoto {
            id
            title
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "thumbnail")
          }
          comments {
            #{COMMENT_FIELDS}
            replies {
              #{COMMENT_FIELDS}
            }
          }
          albums {
            id
            title
            previousPhotoInAlbum(photoId: $id) {
              id
              title
              intelligentOrSquareThumbnailImageUrl: imageUrl(type: "thumbnail")
            }
            nextPhotoInAlbum(photoId: $id) {
              id
              title
              intelligentOrSquareThumbnailImageUrl: imageUrl(type: "thumbnail")
            }
            photoPositionInAlbum(photoId: $id) {
              position
              total
              page
            }
          }
          userTags {
            id
            name
          }
          machineTags {
            id
            name
          }
          labels {
            id
            name: sequencedName
            confidence
            boundingBox {
              top
              left
              width
              height
            }
          }
          intelligentThumbnail {
            boundingBox {
              top
              left
              width
              height
            }
          }
          userThumbnail {
            top
            left
            width
            height
          }
          rekognitionLabelModelVersion
          canEdit
        }
      }
    GQL
    photos_processing: <<-GQL.squish,
      query PhotosProcessingQuery($ids: [ID!]!) {
        photosByIds(ids: $ids) {
          id
          labeled
          processed
          processingFailed
        }
      }
    GQL
    comment_fields: COMMENT_FIELDS
  }.freeze

  # Removed from above as it was not used
  # intelligentThumbnail {
  #   boundingBox {
  #     top
  #     left
  #     width
  #     height
  #   }
  #   centerOfGravity {
  #     top
  #     left
  #   }
  # }
end
