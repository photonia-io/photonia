# frozen_string_literal: true

module Queries
  class TagQuery < BaseQuery
    type Types::TagType, null: false
    description 'Find a tag by ID'

    argument :id, ID, 'ID of the tag', required: true
    argument :page, Integer, 'Page number', required: false

    def resolve(id:, page: nil)
      ActsAsTaggableOn::Tag.friendly.find(id)
    end
  end
end
