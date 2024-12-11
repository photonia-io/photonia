# frozen_string_literal: true

module Types
  # PaginatedPhotoType
  class PaginatedPhotoType < Types::PhotoType.collection_type
    description 'A paginated list of photos (collection and metadata fields)'
  end
end
