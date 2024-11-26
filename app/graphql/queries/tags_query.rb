# frozen_string_literal: true

module Queries
  # Tags Query
  class TagsQuery < BaseQuery
    description 'Find 100 tags'

    type [Types::TagType], null: false

    argument :type, String, 'Type of tag (user or machine)', default_value: 'user', required: false
    argument :order, String, 'Order of tags (most used, least used, newest, oldest)', default_value: 'most_used', required: false
    argument :limit, Integer, 'Number of tags to be returned', required: false

    def resolve(type:, order:, limit: nil)
      tags = fetch_tags(type, order, limit)
      tags || raise(GraphQL::ExecutionError, 'Invalid type or order')
    end

    private

    def fetch_tags(type, order, limit)
      tag_methods = {
        'most_used' => :photonia_most_used,
        'least_used' => :photonia_least_used,
        'newest' => :photonia_latest,
        'oldest' => :photonia_oldest
      }

      method = tag_methods[order]
      return unless method

      if type == 'user'
        ActsAsTaggableOn::Tag.send(method, limit: limit)
      elsif type == 'machine'
        ActsAsTaggableOn::Tag.send(method, rekognition: true, limit: limit)
      end
    end
  end
end
