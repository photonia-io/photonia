# frozen_string_literal: true

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
require 'rails_helper'

RSpec.describe AlbumsPhoto, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
