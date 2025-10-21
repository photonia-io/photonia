# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'removePhotosFromAlbum Mutation', type: :request do
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

  before do
    album.photos << first_photo
    album.photos << second_photo
  end

  let(:variables) do
    {
      albumId: album.slug,
      photoIds: [first_photo.slug, second_photo.slug]
    }
  end

  let(:query) do
    <<~GQL
      mutation RemovePhotosFromAlbum($albumId: String!, $photoIds: [String!]!) {
        removePhotosFromAlbum(albumId: $albumId, photoIds: $photoIds) {
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

    it 'removes the selected photos from the album and returns the album' do
      expect(album.photos).to include(first_photo, second_photo)

      post_mutation

      album.reload
      expect(album.photos).not_to include(first_photo)
      expect(album.photos).not_to include(second_photo)

      payload = data_dig(response, 'removePhotosFromAlbum')
      expect(payload['id']).to eq(album.slug)
    end
  end
end
