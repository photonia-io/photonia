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
      query HomepageQuery {
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
        randomPhotos: photos(mode: "simple", fetchType: "random", limit: 4) {
          collection {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        mostUsedTags: tags(type: "user", order: "most_used", limit: 60) {
          id
          name
          taggingsCount
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
      query PhotosIndexQuery($page: Int, $query: String) {
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
