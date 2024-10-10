# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Albums' do
  context 'when there is an album' do
    let(:photo) { create(:photo) }
    let(:album) { create(:album) }

    before do
      album.photos << photo
      album.public_cover_photo = photo
      album.save
    end

    describe 'GET /albums' do
      it 'returns http success' do
        get "/albums"
        expect(response).to have_http_status(:success)
      end

      it 'contains the album' do
        get "/albums"
        expect(response.body).to include(album.title)
      end
    end

    describe 'GET /albums/{slug}' do
      it 'returns http success' do
        get "/albums/#{album.slug}"
        expect(response).to have_http_status(:success)
      end

      it 'contains the album' do
        get "/albums/#{album.slug}"
        expect(response.body).to include(album.title)
      end
    end

    describe 'GET /albums/feed' do
      it 'returns http success' do
        get "/albums/feed.xml"
        expect(response).to have_http_status(:success)
      end

      it 'contains the album' do
        get "/albums/feed.xml"
        expect(response.body).to include(album.title)
      end
    end
  end
end
