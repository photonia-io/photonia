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

    def resolve(album_id:, sorting_type:, sorting_order:, orders: [])
      model = if orders.any?
                Album.includes(:albums_photos)
              else
                Album
              end
      album = model.friendly.find(album_id)

      return { errors: ['Album not found'], album: nil } unless album

      return { errors: ['Not authorized to update this album'], album: nil } unless context[:authorize].call(album, :update?)

      ActiveRecord::Base.transaction do
        if orders.present?
          orders_photos = Photo.unscoped.where(slug: orders.map { |o| o[:photo_id] })

          ids_and_orderings = []
          orders.each do |order|
            photo = orders_photos.detect { |p| p.slug == order[:photo_id] }
            raise ActiveRecord::Rollback, "Photo #{order[:photo_id]} not found" unless photo

            albums_photo = album.albums_photos.detect { |ap| ap.photo_id == photo.id }
            raise ActiveRecord::Rollback, "Photo #{order[:photo_id]} not found in album" unless albums_photo

            # albums_photo.update!(ordering: order[:position])
            ids_and_orderings << { id: albums_photo.id, ordering: order[:ordering] }
          end

          album.execute_bulk_ordering_update(ids_and_orderings) if ids_and_orderings.any?
        end

        album.sorting_type = translate_sorting_type(sorting_type)
        album.sorting_order = translate_sorting_order(sorting_order)
      end

      album.save

      { album: album, errors: [] }
    rescue StandardError => e
      { album: nil, errors: [e.message] }
    end

    private

    def translate_sorting_type(sorting_type)
      case sorting_type
      when 'takenAt' then 'taken_at'
      when 'postedAt' then 'posted_at'
      when 'title' then 'title'
      when 'manual' then 'manual'
      else
        raise ActiveRecord::Rollback, 'Invalid sorting type'
      end
    end

    def translate_sorting_order(sorting_order)
      case sorting_order
      when 'asc' then 'asc'
      when 'desc' then 'desc'
      else
        raise ActiveRecord::Rollback, 'Invalid sorting order'
      end
    end
  end
end
