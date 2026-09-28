# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photos' do
  context 'when the photo exists' do
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

      it 'lazy-loads the photo thumbnail, so it stays unfetched behind the hidden fallback' do
        get '/photos'
        img = Nokogiri::HTML(response.body).at_css(".boot-fallback img[alt='#{photo.title}']")
        expect(img['loading']).to eq('lazy')
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

      it 'has lang and charset on the document' do
        get "/photos/#{photo.slug}"
        expect(response.body).to include('<html lang="en">')
        expect(response.body).to include('<meta charset="utf-8">')
      end

      it 'has a canonical link to the photo URL' do
        get "/photos/#{photo.slug}"
        expect(response.body).to include(%(<link rel="canonical" href="http://www.example.com/photos/#{photo.slug}">))
      end

      it 'drops non-content query params from the canonical link' do
        get "/photos/#{photo.slug}", params: { inAlbum: 'some-album' }
        expect(response.body).to include(%(<link rel="canonical" href="http://www.example.com/photos/#{photo.slug}">))
      end

      it 'has no robots meta tag' do
        get "/photos/#{photo.slug}"
        expect(response.body).not_to include('name="robots"')
      end

      it 'includes ImageObject structured data' do
        get "/photos/#{photo.slug}"
        json_ld = response.body[%r{<script type="application/ld\+json">(.*?)</script>}m, 1]
        data = JSON.parse(json_ld)
        expect(data['@type']).to eq('ImageObject')
        expect(data['contentUrl']).to be_present
      end
    end

    context 'when the photo has no description' do
      let!(:undescribed_photo) { create(:photo, description: '') }

      it 'falls back to a description built from the title' do
        get "/photos/#{undescribed_photo.slug}"
        expect(response.body).to include(%(<meta name="description" content="#{undescribed_photo.title}.))
      end
    end
  end

  context 'when the photo does not exist' do
    describe 'GET /photos/{slug}' do
      it 'returns 404' do
        get '/photos/does-not-exist'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /photos?q=...' do
    it 'has a noindex robots meta tag on search results' do
      get '/photos?q=anything'
      expect(response.body).to include('name="robots" content="noindex, follow"')
    end
  end

  context 'when a photo is hidden from the feed by a collapsed album' do
    let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }
    let!(:cover) { create(:photo, title: 'Race Cover Photo', image_data: TestData.image_data) }
    let!(:hidden) { create(:photo, title: 'Race Bystander Photo', image_data: TestData.image_data) }

    before do
      album.photos << cover
      album.photos << hidden
      album.maintenance
    end

    describe 'GET /photos' do
      it 'shows the cover but not the hidden photo' do
        get '/photos'

        expect(response.body).to include(cover.title)
        expect(response.body).not_to include(hidden.title)
      end
    end

    describe 'GET /photos/feed' do
      it 'shows the cover but not the hidden photo' do
        get '/photos/feed.xml'

        expect(response.body).to include(cover.title)
        expect(response.body).not_to include(hidden.title)
      end
    end
  end

  context 'when the photo is private' do
    let!(:private_photo) { create(:photo, :private) }

    describe 'GET /photos/{slug}' do
      it 'returns 404' do
        get "/photos/#{private_photo.slug}"
        expect(response).to have_http_status(:not_found)
      end

      it 'does not contain the photo' do
        get "/photos/#{private_photo.slug}"
        expect(response.body).not_to include(private_photo.title)
      end

      it 'has a generic <title>' do
        get "/photos/#{private_photo.slug}"
        expect(response.body).to include('<title>Photo - Photonia</title>')
      end
    end
  end

  describe 'POST /photos' do
    include Devise::Test::IntegrationHelpers

    let(:image) do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/support/images/zell-am-see-with-exif.jpg'), 'image/jpeg')
    end

    before { sign_in(user) }

    context 'when the uploader has a default license' do
      let(:user) { create(:user, :uploader, default_license: 'CC BY 4.0') }

      it "applies the uploader's default license to the new photo" do
        post '/photos', params: { photo: { title: 'Upload Test', image: image } }
        expect(Photo.unscoped.order(:id).last.license).to eq('CC BY 4.0')
      end
    end

    context 'when the uploader has no default license' do
      let(:user) { create(:user, :uploader) }

      it 'leaves the license nil' do
        post '/photos', params: { photo: { title: 'Upload Test', image: image } }
        expect(Photo.unscoped.order(:id).last.license).to be_nil
      end
    end

    context 'when the upload succeeds' do
      let(:user) { create(:user, :uploader) }

      it "returns 201 with the new photo's slug" do
        post '/photos', params: { photo: { title: 'Upload Test', image: image } }
        expect(response).to have_http_status(:created)
        expect(response.parsed_body.dig('photo', 'id')).to eq(Photo.unscoped.order(:id).last.slug)
      end
    end

    context 'when the upload is invalid' do
      let(:user) { create(:user, :uploader) }

      it 'returns 422 with the validation errors' do
        post '/photos', params: { photo: { title: '', description: '', image: image } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end
end
