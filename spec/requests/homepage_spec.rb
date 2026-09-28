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

        # Scoped to the "latest" block: the hidden photo can still
        # legitimately appear elsewhere on the page (it's a valid pick for
        # the Random Photo section - hidden_from_feed only governs
        # feed-like listings), so we only assert it's not shown as if it
        # were the latest photo/album.
        latest_block = Nokogiri::HTML(response.body).at_css('#latest').text
        expect(latest_block).not_to include('Race Bystander')
      end
    end
  end
end
