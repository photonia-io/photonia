# frozen_string_literal: true

module Types
  class HomepageType < Types::BaseObject
    description 'Data for the homepage'

    field :latest_photo, PhotoType, null: false
    field :most_used_tags, [TagType], null: false
    field :random_photo, PhotoType, null: false
  end
end
