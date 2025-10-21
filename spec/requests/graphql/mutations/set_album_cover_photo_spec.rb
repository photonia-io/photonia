# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumCoverPhoto Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:owner) { create(:user) }
  let(:album) { create(:album, user: owner) }
  let(:photo) { create(:photo, user: owner) }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumCoverPhoto(
          albumId: "#{album.slug}",
          photoId: "#{photo.slug}"
        ) {
          album {
            id
            title
          }
          errors
        }
      }
    GQL
  end

  context 'when the album is not found' do
    before do
      album.destroy
    end

    it 'returns payload with errors and no album' do
      post_mutation
      expect(data_dig(response, 'setAlbumCoverPhoto', 'album')).to be_nil
      expect(data_dig(response, 'setAlbumCoverPhoto', 'errors')).to include('Album not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns error payload (authorization fails)' do
      post_mutation
      expect(data_dig(response, 'setAlbumCoverPhoto', 'album')).to be_nil
      expect(data_dig(response, 'setAlbumCoverPhoto', 'errors')).to include('Not authorized to update this album')
    end
  end

  context 'when the user is logged in' do
    before { sign_in(owner) }

    context 'when the photo does not belong to the user' do
      let(:photo) { create(:photo, user: create(:user)) }

      before { album.photos << photo }

      it 'returns an error that the photo does not belong to the user' do
        post_mutation
        expect(data_dig(response, 'setAlbumCoverPhoto', 'album')).to be_nil
        expect(data_dig(response, 'setAlbumCoverPhoto', 'errors')).to include('Photo does not belong to user')
      end
    end

    context 'when the photo is not in the album' do
      it 'returns an error that the photo is not found in album' do
        # NOTE: Do NOT add the photo to the album here
        post_mutation
        expect(data_dig(response, 'setAlbumCoverPhoto', 'album')).to be_nil
        expect(data_dig(response, 'setAlbumCoverPhoto', 'errors')).to include('Photo not found in album')
      end
    end

    context 'when the photo belongs to the user and is in the album' do
      before do
        album.photos << photo
      end

      it 'sets the user cover photo and returns the album in payload' do
        expect(album.reload.user_cover_photo_id).to be_nil

        post_mutation

        payload = data_dig(response, 'setAlbumCoverPhoto')
        expect(payload['errors']).to eq([])

        album_data = payload['album']
        expect(album_data).to include(
          'id' => album.slug,
          'title' => album.title
        )

        expect(album.reload.user_cover_photo_id).to eq(photo.id)
      end
    end

    context 'when the signed-in user cannot edit the album' do
      let(:stranger) { create(:user) }

      before do
        sign_out(owner)
        sign_in(stranger)
        album.photos << photo
      end

      it 'returns an error payload' do
        post_mutation
        expect(data_dig(response, 'setAlbumCoverPhoto', 'album')).to be_nil
        expect(data_dig(response, 'setAlbumCoverPhoto', 'errors')).to include('Not authorized to update this album')
      end
    end
  end
end
