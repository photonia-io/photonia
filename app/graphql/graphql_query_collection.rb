# frozen_string_literal: true

# This is a collection of all the GQL queries to be shared between Rails and the Vue app
class GraphqlQueryCollection
  COLLECTION = {
    homepage_index: <<~GQL.squish,
      query HomepageQuery {
        latestPhoto: photo(fetchType: "latest") {
          id
          title
          extralargeImageUrl: imageUrl(type: "extralarge")
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
          albumShares {
            id
            email
            isRegisteredUser
            visitorUrl
            createdAt
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
    photos_show: <<-GQL.squish
      query PhotosShowQuery($id: ID!) {
        photo(id: $id) {
          id
          title
          description
          descriptionHtml
          largeImageUrl: imageUrl(type: "large")
          extralargeImageUrl: imageUrl(type: "extralarge")
          takenAt
          isTakenAtFromExif
          exifExists
          exifCameraFriendlyName
          exifFNumber
          exifExposureTime
          exifFocalLength
          exifIso
          postedAt
          impressionsCount
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
            id
            body
            bodyHtml
            bodyEdited
            bodyLastEditedAt
            flickrUser {
              nsid
              username
              realname
              profileurl
              iconfarm
              iconserver
            }
            createdAt
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
