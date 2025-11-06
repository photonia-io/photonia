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

    def id
      @object.slug
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(Photo.distinct.tagged_with(@object).order(posted_at: :desc), page:)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.limit }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end

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
