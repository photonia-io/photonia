# frozen_string_literal: true

module Types
  # GraphQL Photo Type
  class PhotoType < Types::BaseObject
    description 'A Photo'

    field :albums, [AlbumType], 'Albums the photo belongs to', null: true
    field :can_edit, Boolean, 'Whether the user can edit the photo', null: false
    field :comments, [CommentType], 'Comments on the photo', null: true
    field :description, String, 'Description', null: false
    field :description_html, String, 'Description in HTML', null: true
    field :exif_camera_friendly_name, String, 'Camera friendly name', null: true
    field :exif_exists, Boolean, 'Whether EXIF data exists', null: true
    field :exif_exposure_time, String, 'Exposure time', null: true
    field :exif_f_number, Float, 'F number', null: true
    field :exif_focal_length, Float, 'Focal length', null: true
    field :exif_iso, Integer, 'ISO', null: true
    field :height, Integer, 'Height of the photo in pixels', null: true
    field :id, String, 'ID of the photo', null: false
    field :impressions_count, Integer, 'Number of impressions', null: true
    field :intelligent_thumbnail, IntelligentThumbnailType, 'Intelligent thumbnail', null: true
    field :is_cover_photo, Boolean, 'Whether the photo is a cover photo', null: true
    field :labels, [LabelType], 'Labels', null: true
    field :license, String, 'License type of the photo', null: true
    field :machine_tags, [TagType], 'Machine (Rekognition) tags', null: true
    field :next_photo, PhotoType, 'Next photo', null: true
    field :ordering, Integer, 'Ordering of the photo in the album', null: true
    field :posted_at, GraphQL::Types::ISO8601DateTime, 'Datetime the photo was posted', null: true
    field :previous_photo, PhotoType, 'Previous photo', null: true
    field :privacy, String, 'Privacy level of the photo', null: false
    field :ratio, Float, 'Ratio of the photo', null: true
    field :rekognition_label_model_version, String, 'Rekognition label model version', null: true
    field :scanned, Boolean, 'Whether the photo is a scan of a print or negative', null: false
    field :taken_at, GraphQL::Types::ISO8601DateTime, 'Datetime the photo was taken', null: true
    field :taken_at_info, TakenAtInfoType, 'Precision-aware breakdown of taken_at', null: true
    field :title, String, 'Title of the photo', null: false
    field :user_tags, [TagType], 'User (non-Rekognition) tags', null: true
    field :user_thumbnail, BoundingBoxType, 'User-defined thumbnail', null: true
    field :width, Integer, 'Width of the photo in pixels', null: true

    field :image_url, String, null: false do
      description 'URL of the image'
      argument :type, String, 'Type of the URL', required: true
    end

    field :image_dimensions, ImageDimensionsType, null: true do
      description "Pixel dimensions of the derivative actually served for this type - not the original's"
      argument :type, String, 'Type of the image', required: true
    end

    def id
      @object.slug
    end

    def description
      @object.description || ''
    end

    def labels
      @object.labels.load.add_sequenced_names
    end

    def user_tags
      @object.tags.rekognition(false)
    end

    def machine_tags
      @object.tags.rekognition(true)
    end

    def previous_photo
      base = Pundit.policy_scope(context[:current_user], Photo.unscoped)
      base.where('posted_at < ? OR (posted_at = ? AND id < ?)', @object.posted_at, @object.posted_at, @object.id)
          .order(posted_at: :desc, id: :desc)
          .first
    end

    def next_photo
      base = Pundit.policy_scope(context[:current_user], Photo.unscoped)
      base.where('posted_at > ? OR (posted_at = ? AND id > ?)', @object.posted_at, @object.posted_at, @object.id)
          .order(:posted_at, :id)
          .first
    end

    # Priority within a fallback chain: user-defined > intelligent > square
    DERIVATIVE_FALLBACKS = {
      'thumbnail' => %i[thumbnail_user thumbnail_intelligent thumbnail_square],
      'intelligent_or_square_thumbnail' => %i[thumbnail_user thumbnail_intelligent thumbnail_square],
      'medium' => %i[medium_user medium_intelligent medium_square],
      'intelligent_or_square_medium' => %i[medium_user medium_intelligent medium_square]
    }.freeze

    def image_url(type:)
      name = resolved_derivative(type)
      return '' unless name

      @object.image_url(name).presence || ''
    end

    def image_dimensions(type:)
      name = resolved_derivative(type)
      return nil unless name

      dimensions = @object.derivative_dimensions(name)
      return nil unless dimensions

      { width: dimensions[:width], height: dimensions[:height] }
    end

    def impressions_count
      total_impressions_count = @object.impressions_count + @object.flickr_impressions_count
      total_impressions_count.zero? ? 1 : total_impressions_count
    end

    def taken_at_info
      @object.taken_at_info
    end

    def rekognition_label_model_version
      (@object.rekognition_response && @object.rekognition_response['label_model_version'].presence) || ''
    end

    def width
      @object.pixel_width
    end

    def height
      @object.pixel_height
    end

    def exif_exists
      @object.exif_exists?
    end

    def can_edit
      Pundit.policy(context[:current_user], @object)&.edit?
    end

    def ordering
      # Only resolve if album and albums_photos are present
      album = context[:album]
      return nil unless album

      albums_photos = object.try(:albums_photos)
      return nil unless albums_photos

      albums_photos.detect { |ap| ap.album_id == album.id }&.ordering
    end

    def is_cover_photo
      # Only resolve if the photo is queried in the context of an album
      album = context[:album]
      return nil unless album

      if album.public_cover_photo_id == @object.id
        true
      elsif Pundit.policy(context[:current_user], album)&.update?
        album.user_cover_photo_id == @object.id
      end
    end

    def albums
      Pundit.policy_scope(context[:current_user], @object.albums.unscope(where: :privacy))
    end

    def user_thumbnail
      return nil if @object.user_thumbnail.blank?

      {
        top: @object.user_thumbnail['top'],
        left: @object.user_thumbnail['left'],
        width: @object.user_thumbnail['width'],
        height: @object.user_thumbnail['height']
      }
    end

    private

    # Resolves a requested image "type" to the derivative name that is
    # actually served for it, so image_url and image_dimensions can never
    # disagree about which derivative they're describing.
    def resolved_derivative(type)
      DERIVATIVE_FALLBACKS.fetch(type) { [type.to_sym] }.find { |name| @object.image_url(name).present? }
    end
  end
end
