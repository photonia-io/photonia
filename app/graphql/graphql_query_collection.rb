# frozen_string_literal: true

# This is a collection of all the GQL queries to be shared between Rails and the Vue app
class GraphqlQueryCollection
  COLLECTION = {
    homepage: <<-GQL.squish
      query HomepageQuery {
        homepage {
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
      }
    GQL
  }.freeze
end
