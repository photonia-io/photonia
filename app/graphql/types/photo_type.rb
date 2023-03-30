# frozen_string_literal: true

module Types
  # GraphQL Photo Type
  class PhotoType < Types::BaseObject
    description 'A Photo'

    field :albums, [AlbumType], 'Albums the photo belongs to', null: true
    field :date_taken, GraphQL::Types::ISO8601DateTime, 'Datetime the photo was taken', null: true
    field :description, String, 'Description', null: false
    field :id, String, 'ID of the photo', null: false
    field :imported_at, GraphQL::Types::ISO8601DateTime, 'Datetime the photo was imported', null: true
    field :intelligent_thumbnail, IntelligentThumbnailType, 'Intelligent thumbnail', null: true
    field :label_instances, [LabelInstanceType], 'Label instances', null: true
    field :license, String, 'License type of the photo', null: true
    field :machine_tags, [TagType], 'Machine (Rekognition) tags', null: true
    field :name, String, 'Title of the photo', null: false
    field :next_photo, PhotoType, 'Next photo', null: true
    field :previous_photo, PhotoType, 'Previous photo', null: true
    field :user_tags, [TagType], 'User (non-Rekognition) tags', null: true

    field :image_url, String, null: false do
      description 'URL of the image'
      argument :type, String, 'Type of the URL', required: true
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
