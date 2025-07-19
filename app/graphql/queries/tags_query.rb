# frozen_string_literal: true

module Queries
  # Tags Query
  class TagsQuery < BaseQuery
    description 'Find 100 tags'

    type [Types::TagType], null: false

    argument :limit, Integer, 'Number of tags to be returned', required: false
    argument :order, String, 'Order of tags (most used, least used, newest, oldest)', default_value: 'most_used', required: false
    argument :query, String, 'Search query for tag suggestions', required: false
    argument :type, String, 'Type of tag (user or machine)', default_value: 'user', required: false

    def resolve(type:, order:, limit: nil, query: nil)
      tags = if query.present?
               search_tags(type, query, limit)
             else
               fetch_tags(type, order, limit)
             end
      tags || raise(GraphQL::ExecutionError, 'Invalid type or order')
    end

    private

    def search_tags(type, query, limit)
      limit ||= 10
      if type == 'user'
        search_user_tags(query, limit)
      elsif type == 'machine'
        search_machine_tags(query, limit)
      end
    end

    def search_user_tags(query, limit)
      ActsAsTaggableOn::Tag.photonia_most_used(rekognition: false, limit: limit)
                           .where('name LIKE ?', "#{sanitize_like(query)}%")
    end

    def search_machine_tags(query, limit)
      ActsAsTaggableOn::Tag.photonia_most_used(rekognition: true, limit: limit)
                           .where('name LIKE ?', "#{sanitize_like(query)}%")
    end

    def sanitize_like(string)
      # Escape special characters (%, _, \) for SQL LIKE queries
      string.gsub(/[%_\\]/) { |x| "\\#{x}" }
    end

    def fetch_tags(type, order, limit)
      method = tag_methods[order]
      return unless method

      if type == 'user'
        ActsAsTaggableOn::Tag.send(method, limit: limit)
      elsif type == 'machine'
        ActsAsTaggableOn::Tag.send(method, rekognition: true, limit: limit)
      end
    end

    def tag_methods
      {
        'most_used' => :photonia_most_used,
        'least_used' => :photonia_least_used,
        'newest' => :photonia_latest,
        'oldest' => :photonia_oldest
      }
    end
  end
end
