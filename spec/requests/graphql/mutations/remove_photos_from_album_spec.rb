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
          album {
            id
            title
            photos {
              collection {
                id
              }
            }
          }
          errors
        }
      }
    GQL
  end

  context 'when the album is not found' do
    before { album.destroy }

    it 'returns payload with errors and no album' do
      post_mutation
      expect(data_dig(response, 'removePhotosFromAlbum', 'album')).to be_nil
      expect(data_dig(response, 'removePhotosFromAlbum', 'errors')).to include('Album not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns error payload (authorization fails)' do
      post_mutation
      expect(data_dig(response, 'removePhotosFromAlbum', 'album')).to be_nil
      expect(data_dig(response, 'removePhotosFromAlbum', 'errors')).to include('Not authorized to update this album')
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
      expect(payload['errors']).to eq([])

      album_data = payload['album']
      expect(album_data['id']).to eq(album.slug)
    end

    context 'when one or more photos are not found' do
      let(:variables) do
        {
          albumId: album.slug,
          photoIds: [first_photo.slug, 'nonexistent-slug']
        }
      end

      it 'returns an error and does not modify the album' do
        expect do
          post_mutation
        end.not_to(change { album.reload.photos.count })

        expect(data_dig(response, 'removePhotosFromAlbum', 'album')).to be_nil
        expect(data_dig(response, 'removePhotosFromAlbum', 'errors')).to include('One or more photos not found')
      end
    end

    context 'when trying to remove a photo not authorized for update' do
      let(:stranger) { create(:user) }
      let(:stranger_photo) { create(:photo, user: stranger) }

      let(:variables) do
        {
          albumId: album.slug,
          photoIds: [first_photo.slug, stranger_photo.slug]
        }
      end

      before do
        # Ensure the stranger photo is in the album to attempt removal
        album.photos << stranger_photo
      end

      it 'returns an authorization error and does not modify the album' do
        initial_count = album.photos.count

        expect do
          post_mutation
        end.not_to change { album.reload.photos.count }.from(initial_count)

        expect(data_dig(response, 'removePhotosFromAlbum', 'album')).to be_nil
        expect(data_dig(response, 'removePhotosFromAlbum', 'errors')).to include('Not authorized to update this photo')
      end
    end
  end
end
