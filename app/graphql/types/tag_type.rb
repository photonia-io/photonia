# frozen_string_literal: true

module Types
  # GraphQL Tag Type
  class TagType < Types::BaseObject
    description 'A tag'
    field :id, String, 'ID of the tag', null: false
    field :name, String, 'Name of the tag', null: true
    field :photos, Types::PaginatedPhotoType, 'Photos tagged with this tag', null: true do
      argument :page, Integer, 'Page number', required: false
    end
    field :taggings_count, Integer, 'Number of photos tagged with this tag', null: true

    # Related tags suggestions, precomputed from public photos using user + Flickr tags (excludes Rekognition).
    field :related_tags, [Types::TagType], 'Related tags based on co-occurrence', null: false do
      argument :limit, Integer, 'Max number of suggestions to return', required: false, default_value: 10
      argument :min_confidence, Float, 'Minimum confidence threshold', required: false, default_value: 0.3
      argument :min_support, Integer, 'Minimum co-occurrence count', required: false, default_value: 2
    end

    ##
    # Exposes the tag's slug as its ID.
    # @return [String] The tag's slug used as the ID.
    def id
      @object.slug
    end

    ##
    # Fetches photos tagged with this tag, paginated and ordered by posted_at descending.
    # @param [Integer, nil] page - Page number to fetch; when nil, defaults to the first page determined by the paginator.
    # @return [Enumerable<Photo>] A collection of photos for the requested page, extended with pagination metadata methods:
    #   `total_pages`, `current_page`, `limit_value`, and `total_count`.
    def photos(page: nil)
      pagy, @photos = context[:pagy].call(Photo.distinct.tagged_with(@object).order(posted_at: :desc), page:)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.limit }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end

    ##
    # Fetches tags related to this tag based on co-occurrence and confidence thresholds.
    # @param [Integer] limit - Maximum number of related tags to return (default: 10).
    # @param [Integer] min_support - Minimum co-occurrence count required for a relation (default: 2).
    # @param [Float] min_confidence - Minimum confidence required for a relation, between 0 and 1 (default: 0.3).
    # @return [Array<Types::TagType>] An array of related tag objects ordered for suggestion.
    def related_tags(limit: 10, min_support: 2, min_confidence: 0.3)
      RelatedTag
        .includes(:to_tag)
        .where(tag_id_from: @object.id)
        .with_thresholds(min_support:, min_confidence:)
        .ordered_for_suggestion
        .limit(limit)
        .map(&:to_tag)
    end
  end
end
