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
          id
          title
        }
      }
    GQL
  end

  context 'when the album is not found' do
    before { album.destroy }

    it 'returns an error' do
      post_mutation
      expect(first_error_message(response)).to eq('Album not found')
    end
  end

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in but is not the owner' do
    before { sign_in(create(:user)) }

    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in and is the owner' do
    before { sign_in(album.user) }

    it 'deletes the album and returns it' do
      expect { post_mutation }.to change { Album.count }.by(-1)
      data = data_dig(response, 'deleteAlbum')
      expect(data).to include(
        'id' => album.slug,
        'title' => album.title
      )
    end
  end
end
