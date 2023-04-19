# frozen_string_literal: true

module Types
  # GraphQL Homepage Type
  class HomepageType < Types::BaseObject
    description 'Data for the homepage'

    field :latest_photo, PhotoType, 'Latest photo', null: false
    field :most_used_tags, [TagType], 'List of most used tags', null: false
    field :random_photos, [PhotoType], 'Random photos', null: false
  end
end
