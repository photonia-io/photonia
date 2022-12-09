# frozen_string_literal: true

module Types
  # GraphQL Photo Type
  class PhotoType < Types::BaseObject
    description 'A Photo'

    field :id, String, null: false
    field :name, String, null: true
    field :description, String, null: false
    field :date_taken, GraphQL::Types::ISO8601DateTime, null: true
    field :imported_at, GraphQL::Types::ISO8601DateTime, null: true
    field :license, String, null: true
    field :user_tags, [TagType], null: true
    field :machine_tags, [TagType], null: true
    field :albums, [AlbumType], null: true
    field :previous_photo, PhotoType, null: true
    field :next_photo, PhotoType, null: true
    field :label_instances, [LabelInstanceType], null: true
    field :intelligent_thumbnail, IntelligentThumbnailType, null: true

    field :image_url, String, null: false do
      argument :type, String, required: true
    end

    def id
      @object.slug
    end

    def description
      @object.description || ''
    end

    def user_tags
      @object.tags.rekognition(false)
    end

    def machine_tags
      @object.tags.rekognition(true)
    end

    def previous_photo
      @object.prev
    end

    def next_photo
      @object.next
    end

    def image_url(type:)
      case type
      when 'intelligent_or_square_medium'
        @object.image_url(:medium_intelligent).presence || @object.image_url(:medium_square)
      when 'intelligent_or_square_thumbnail'
        @object.image_url(:thumbnail_intelligent).presence || @object.image_url(:thumbnail_square)
      else
        @object.image_url(type.to_sym)
      end
    end
  end
end
