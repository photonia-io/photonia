# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photos' do
  context 'when photo exists' do
    let!(:photo) { create(:photo, :with_taken_at, image_data: TestData.image_data) }

    describe 'GET /photos' do
      it 'returns http success' do
        get '/photos'
        expect(response).to have_http_status(:success)
      end

      it 'contains the photo' do
        get '/photos'
        expect(response.body).to include(photo.title)
      end
    end

    describe 'GET /photos?q=photo_title' do
      let(:url_encoded_title) { CGI.escape(photo.title) }

      it 'returns http success' do
        get "/photos?q=#{url_encoded_title}"
        expect(response).to have_http_status(:success)
      end

      it 'contains the photo' do
        get "/photos?q=#{url_encoded_title}"
        expect(response.body).to include(photo.title)
      end
    end

    describe 'GET /photos/feed' do
      it 'returns http success' do
        get '/photos/feed.xml'
        expect(response).to have_http_status(:success)
      end

      it 'contains the photo' do
        get '/photos/feed.xml'
        expect(response.body).to include(photo.title)
      end
    end

    describe 'GET /photos/{slug}' do
      it 'returns http success' do
        get "/photos/#{photo.slug}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
