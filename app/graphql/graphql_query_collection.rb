# frozen_string_literal: true

# This is a collection of all the GQL queries to be shared between Rails and the Vue app
class GraphqlQueryCollection
  COLLECTION = {
    homepage_index: <<-GQL.squish,
      query HomepageQuery {
        latestPhoto {
          id
          title
          extralargeImageUrl: imageUrl(type: "extralarge")
        }
        randomPhotos {
          id
          title
          intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
        }
        mostUsedTags {
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
            publicPhotosCount
            publicCoverPhoto {
              intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
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
          photos(page: $page) {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
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
    tags_index: <<-GQL.squish,
      query TagsIndexQuery {
        mostUsedUserTags {
          id
          name
          taggingsCount
        }
        leastUsedUserTags {
          id
          name
          taggingsCount
        }
        mostUsedMachineTags {
          id
          name
          taggingsCount
        }
        leastUsedMachineTags {
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
          photos(page: $page) {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
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
            intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
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
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
          }
          nextPhoto {
            id
            title
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
          }
          albums {
            id
            title
            previousPhotoInAlbum(photoId: $id) {
              id
              title
              intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
            }
            nextPhotoInAlbum(photoId: $id) {
              id
              title
              intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
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
            centerOfGravity {
              top
              left
            }
          }
          rekognitionLabelModelVersion
        }
      }
    GQL
  }.freeze
end
