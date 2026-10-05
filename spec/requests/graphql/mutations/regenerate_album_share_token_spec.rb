# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'regenerateAlbumShareToken Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album, share_mode: 'all_photos').tap(&:regenerate_share_token!) }

  let(:query) do
    <<~GQL
      mutation {
        regenerateAlbumShareToken(id: "#{album.slug}") {
          id
          shareToken
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns a NOT_FOUND error and nulls regenerateAlbumShareToken' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'regenerateAlbumShareToken')).to be_nil
    end
  end

  context 'when logged in as a different user' do
    before { sign_in(create(:user)) }

    it 'returns a NOT_FOUND error' do
      post_mutation
      json = response.parsed_body

      expect(json['errors'].first.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(album.user) }

    it 'replaces the share token so the previous link stops working' do
      previous_token = album.share_token

      post_mutation
      json = response.parsed_body
      new_token = json.dig('data', 'regenerateAlbumShareToken', 'shareToken')

      expect(new_token).to be_present
      expect(new_token).not_to eq(previous_token)
      expect(album.reload.share_token).to eq(new_token)
      expect(AlbumShareAccess.resolve(album.slug, previous_token)).to be_nil
      expect(AlbumShareAccess.resolve(album.slug, new_token)).to be_present
    end
  end
end
