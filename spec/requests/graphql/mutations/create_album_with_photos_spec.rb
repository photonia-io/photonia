# frozen_string_literal: true

require 'rails_helper'

describe 'createAlbumWithPhotos Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:owner) { create(:user, :uploader) }
  let(:title) { 'New album' }
  let(:photo) { create(:photo, user: owner) }

  let(:query) do
    <<~GQL
      mutation {
        createAlbumWithPhotos(title: "#{title}", photoIds: ["#{photo.slug}"]) {
          id
          title
          photos {
            collection {
              id
            }
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls createAlbumWithPhotos' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'createAlbumWithPhotos')).to be_nil
    end
  end

  context 'when the owner is logged in' do
    before { sign_in(owner) }

    it 'creates the album with the photo' do
      post_mutation
      data = response.parsed_body['data']['createAlbumWithPhotos']

      expect(data['title']).to eq(title)
      collection_ids = data['photos']['collection'].pluck('id')
      expect(collection_ids).to include(photo.slug)
    end

    context 'when the photo is private' do
      let(:photo) { create(:photo, user: owner, privacy: :private) }

      it 'creates the album with the private photo' do
        post_mutation
        data = response.parsed_body['data']['createAlbumWithPhotos']

        expect(data).to be_present
        collection_ids = data['photos']['collection'].pluck('id')
        expect(collection_ids).to include(photo.slug)
      end
    end
  end

  context 'when a stranger tries to add a private photo they do not own' do
    let(:stranger) { create(:user, :uploader) }
    let(:photo) { create(:photo, user: owner, privacy: :private) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND error and nulls createAlbumWithPhotos' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'createAlbumWithPhotos')).to be_nil
    end

    it 'does not create the album' do
      expect { post_mutation }.not_to change(Album, :count)
    end
  end

  context 'when the selection mixes an owned photo and one belonging to someone else' do
    let(:owner) { create(:user, :uploader) }
    let(:other_photo) { create(:photo, user: stranger, privacy: :private) }

    let(:query) do
      <<~GQL
        mutation {
          createAlbumWithPhotos(title: "#{title}", photoIds: ["#{photo.slug}", "#{other_photo.slug}"]) {
            id
          }
        }
      GQL
    end

    before { sign_in(owner) }

    it 'creates no album and adds neither photo' do
      expect { post_mutation }.not_to change(Album, :count)
      expect(photo.albums).to be_empty
    end
  end
end
