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

RSpec.describe AlbumsPhoto do
  describe 'associations' do
    it 'belongs to an album' do
      association = described_class.reflect_on_association(:album)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a photo' do
      association = described_class.reflect_on_association(:photo)
      expect(association.macro).to eq :belongs_to
    end
  end
end
