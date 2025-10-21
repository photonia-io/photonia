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
        get '/albums'
        expect(response).to have_http_status(:success)
      end

      it 'contains the album' do
        get '/albums'
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
        get '/albums/feed.xml'
        expect(response).to have_http_status(:success)
      end

      it 'contains the album' do
        get '/albums/feed.xml'
        expect(response.body).to include(album.title)
      end
    end
  end

  context "when there's a private album" do
    let(:photo) { create(:photo) }
    let(:private_album) { create(:album, privacy: 'private') }

    before do
      private_album.photos << photo
      private_album.public_cover_photo = photo
      private_album.save
    end

    describe 'GET /albums' do
      it 'does not contain the private album' do
        get '/albums'
        expect(response.body).not_to include(private_album.title)
      end
    end

    describe 'GET /album/{slug}' do
      it 'returns http success' do
        get "/albums/#{private_album.slug}"
        expect(response).to have_http_status(:success)
      end

      it 'does not contain the album' do
        get "/albums/#{private_album.slug}"
        expect(response.body).not_to include(private_album.title)
      end

      it 'has a generic <title>' do
        get "/albums/#{private_album.slug}"
        expect(response.body).to include('<title>Album - Photonia</title>')
      end
    end
  end
end
