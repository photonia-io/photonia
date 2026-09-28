# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Homepage' do
  describe 'GET /' do
    context 'when the latest photo is an ordinary one' do
      let!(:photo) { create(:photo, image_data: TestData.image_data) }

      it 'shows the plain latest-photo block' do
        get '/'

        expect(response.body).to include('Latest photo')
        expect(response.body).to include(photo.title)
      end
    end

    context 'when the latest photo is a collapsed album\'s cover' do
      let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }
      let!(:cover) { create(:photo, title: 'Race Cover', image_data: TestData.image_data) }
      let!(:hidden) { create(:photo, title: 'Race Bystander', image_data: TestData.image_data) }

      before do
        album.photos << cover
        album.photos << hidden
        album.maintenance
      end

      it 'shows the album link and photo count instead' do
        get '/'

        expect(response.body).to include('Latest album')
        expect(response.body).to include(album.title)
        expect(response.body).to include('2 photos')
        expect(response.body).to include(album_path(album))
        expect(response.body).not_to include('Race Bystander')
      end
    end
  end
end
