# frozen_string_literal: true

# Links photos to albums

# == Schema Information
#
# Table name: albums_photos
#
#  id         :bigint           not null, primary key
#  cover      :boolean          default(FALSE)
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
end
