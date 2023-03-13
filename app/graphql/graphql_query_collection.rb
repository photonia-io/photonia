# frozen_string_literal: true

# This is a collection of all the GQL queries to be shared between Rails and the Vue app
class GraphqlQueryCollection
  COLLECTION = {
    homepage_index: <<-GQL.squish,
      query HomepageQuery {
        latestPhoto {
          id
          name
          extralargeImageUrl: imageUrl(type: "extralarge")
        }
        randomPhoto {
          id
          name
          largeImageUrl: imageUrl(type: "large")
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
            photosCount
            coverPhoto {
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
      query AlbumsShowQuery($id: ID!) {
        album(id: $id) {
          title
          description
          photos {
            id
            name
            intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
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
              name
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
      query PhotosIndexQuery($page: Int) {
        photos(page: $page) {
          collection {
            id
            name
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
          name
          description
          largeImageUrl: imageUrl(type: "large")
          dateTaken
          importedAt
          previousPhoto {
            id
            name
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
          }
          nextPhoto {
            id
            name
            intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
          }
          albums {
            id
            title
            previousPhotoInAlbum(photoId: $id) {
              id
              name
              intelligentOrSquareThumbnailImageUrl: imageUrl(type: "intelligent_or_square_thumbnail")
            }
            nextPhotoInAlbum(photoId: $id) {
              id
              name
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
          labelInstances {
            name
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
            centerOfGravityTop
            centerOfGravityLeft
          }
        }
      }
    GQL
  }.freeze
end
