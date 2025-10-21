# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'addPhotosToAlbum Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) do
    post '/graphql',
         params: {
           query: query,
           variables: variables
         }
  end

  let(:owner) { create(:user) }
  let(:album) { create(:album, user: owner) }
  let(:first_photo) { create(:photo, user: owner) }
  let(:second_photo) { create(:photo, user: owner) }

  let(:variables) do
    {
      albumId: album.slug,
      photoIds: [first_photo.slug, second_photo.slug]
    }
  end

  let(:query) do
    <<~GQL
      mutation AddPhotosToAlbum($albumId: String!, $photoIds: [String!]!) {
        addPhotosToAlbum(albumId: $albumId, photoIds: $photoIds) {
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
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    before { sign_in(owner) }

    it 'adds the selected photos to the album and returns the album' do
      expect(album.photos).not_to include(first_photo, second_photo)

      post_mutation

      album.reload
      expect(album.photos).to include(first_photo)
      expect(album.photos).to include(second_photo)

      payload = data_dig(response, 'addPhotosToAlbum')
      expect(payload['id']).to eq(album.slug)

      collection_ids = data_dig(response, 'addPhotosToAlbum', 'photos', 'collection').pluck('id')
      expect(collection_ids).to include(first_photo.slug, second_photo.slug)
    end

    it 'does not duplicate photos if mutation is called twice' do
      post_mutation
      expect { post_mutation }.not_to raise_error

      album.reload
      slugs = album.photos.pluck(:slug)
      expect(slugs.count(first_photo.slug)).to eq(1)
      expect(slugs.count(second_photo.slug)).to eq(1)
    end
  end
end
