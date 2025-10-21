# frozen_string_literal: true

# Links photos to albums

# == Schema Information
#
# Table name: albums_photos
#
#  id         :bigint           not null, primary key
#  ordering   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  album_id   :bigint           not null
#  photo_id   :bigint           not null
#
# Indexes
#
#  index_albums_photos_on_album_id  (album_id)
#  index_albums_photos_on_photo_id  (photo_id)
#
# Foreign Keys
#
#  fk_rails_...  (album_id => albums.id)
#  fk_rails_...  (photo_id => photos.id)
#
class AlbumsPhoto < ApplicationRecord
  belongs_to :album
  belongs_to :photo

  validates :album_id, uniqueness: { scope: :photo_id }

  before_validation :set_ordering

  private

  def set_ordering
    return unless ordering.nil?

    maximum_ordering = AlbumsPhoto.where(album_id: album_id).maximum(:ordering)
    self.ordering = maximum_ordering.nil? ? 100_000 : maximum_ordering + 100_000
  end
end
