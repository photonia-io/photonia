# frozen_string_literal: true

module Mutations
  # GraphQL Mutation to update the order of photos in an album
  class UpdateAlbumPhotoOrder < BaseMutation
    description 'Update the order of photos in an album'

    argument :album_id, ID, required: true, description: 'ID of the album'
    argument :orders, [Types::AlbumPhotoOrderInput], required: false, description: 'List of photo IDs with their new ordering values'
    argument :sorting_order, String, required: true, description: 'Sorting direction'
    argument :sorting_type, String, required: true, description: 'Sorting type'

    field :album, Types::AlbumType, null: true, description: 'The album with updated photo order'
    field :errors, [String], null: false, description: 'List of errors encountered during the operation'

    SORTING_TYPES = {
      'takenAt' => 'taken_at',
      'postedAt' => 'posted_at',
      'title' => 'title',
      'manual' => 'manual'
    }.freeze

    SORTING_ORDERS = {
      'asc' => 'asc',
      'desc' => 'desc'
    }.freeze

    def resolve(album_id:, sorting_type:, sorting_order:, orders: [])
      # Validate sorting parameters early
      translated_type = SORTING_TYPES[sorting_type]
      translated_order = SORTING_ORDERS[sorting_order]

      return error_response('Invalid sorting type') unless translated_type
      return error_response('Invalid sorting order') unless translated_order

      # Load album with associations only if needed
      album = load_album(album_id, orders.present?)
      return error_response('Album not found') unless album

      # Authorize
      begin
        context[:authorize].call(album, :update?)
      rescue Pundit::NotAuthorizedError
        return error_response('Not authorized to update this album')
      end

      # Process updates
      errors = update_album(album, orders, translated_type, translated_order)

      { album: errors.empty? ? album : nil, errors: errors }
    end

    private

    def load_album(album_id, include_associations)
      base = Pundit.policy_scope(context[:current_user], Album.unscoped)
      query = include_associations ? base.includes(:albums_photos) : base
      query.friendly.find(album_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def update_album(album, orders, sorting_type, sorting_order)
      errors = []

      ActiveRecord::Base.transaction do
        if orders.present?
          errors = process_photo_orders(album, orders)
          raise ActiveRecord::Rollback if errors.any?
        end

        album.sorting_type = sorting_type
        album.sorting_order = sorting_order
        album.save!
      end

      errors
    end

    def process_photo_orders(album, orders)
      errors = []

      # We need to disable the RuboCop rule here because this might be an array
      # rubocop:disable Rails/Pluck
      photo_slugs = orders.map { |o| o[:photo_id] }
      # rubocop:enable Rails/Pluck

      # Build hash maps for O(1) lookups
      photos_by_slug = Photo.unscoped.where(slug: photo_slugs).index_by(&:slug)
      albums_photos_by_photo_id = album.albums_photos.index_by(&:photo_id)

      ids_and_orderings = orders.filter_map do |order|
        photo = photos_by_slug[order[:photo_id]]
        unless photo
          errors << "Photo #{order[:photo_id]} not found"
          next
        end

        albums_photo = albums_photos_by_photo_id[photo.id]
        unless albums_photo
          errors << "Photo #{order[:photo_id]} not found in album"
          next
        end

        { id: albums_photo.id, ordering: order[:ordering] }
      end

      return errors if errors.any?

      album.execute_bulk_ordering_update(ids_and_orderings) if ids_and_orderings.any?
      errors
    end

    def error_response(message)
      { errors: [message], album: nil }
    end
  end
end
