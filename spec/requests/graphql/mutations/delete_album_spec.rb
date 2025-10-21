# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'deleteAlbum Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }

  let(:query) do
    <<~GQL
      mutation {
        deleteAlbum(id: "#{album.slug}") {
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
    before { album.destroy }

    it 'returns payload with errors and no album' do
      post_mutation
      expect(data_dig(response, 'deleteAlbum', 'album')).to be_nil
      expect(data_dig(response, 'deleteAlbum', 'errors')).to include('Album not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns error payload' do
      post_mutation
      expect(data_dig(response, 'deleteAlbum', 'album')).to be_nil
      expect(data_dig(response, 'deleteAlbum', 'errors')).to include('Not authorized to delete this album')
    end
  end

  context 'when the user is logged in but is not the owner' do
    before { sign_in(create(:user)) }

    it 'returns error payload' do
      post_mutation
      expect(data_dig(response, 'deleteAlbum', 'album')).to be_nil
      expect(data_dig(response, 'deleteAlbum', 'errors')).to include('Not authorized to delete this album')
    end
  end

  context 'when the user is logged in and is the owner' do
    before { sign_in(album.user) }

    it 'deletes the album and returns it in payload' do
      expect { post_mutation }.to change { Album.count }.by(-1)
      payload = data_dig(response, 'deleteAlbum')
      expect(payload['errors']).to eq([])
      album_data = payload['album']
      expect(album_data).to include(
        'id' => album.slug,
        'title' => album.title
      )
    end
  end
end
