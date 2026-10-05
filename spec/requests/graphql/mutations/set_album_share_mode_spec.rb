# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumShareMode Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }
  let(:mode) { 'all_photos' }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumShareMode(id: "#{album.slug}", mode: "#{mode}") {
          id
          shareMode
          shareToken
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns a NOT_FOUND error and nulls setAlbumShareMode' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'setAlbumShareMode')).to be_nil
    end
  end

  context 'when logged in as a different user' do
    before { sign_in(create(:user)) }

    it 'returns a NOT_FOUND error' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(album.user) }

    it 'turns sharing on and generates a token' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setAlbumShareMode']

      expect(data['shareMode']).to eq('all_photos')
      expect(data['shareToken']).to be_present
      expect(album.reload.share_mode).to eq('all_photos')
    end

    it 'keeps the same token across a mode switch' do
      post_mutation
      token_after_first = response.parsed_body.dig('data', 'setAlbumShareMode', 'shareToken')

      # A sign-in doesn't carry over a second `post` within the same example,
      # so it's repeated here.
      sign_in(album.user)
      post '/graphql', params: {
        query: <<~GQL
          mutation { setAlbumShareMode(id: "#{album.slug}", mode: "public_photos") { shareMode shareToken } }
        GQL
      }
      data = response.parsed_body['data']['setAlbumShareMode']

      expect(data['shareMode']).to eq('public_photos')
      expect(data['shareToken']).to eq(token_after_first)
    end

    context 'when turning sharing off' do
      before do
        album.update_columns(share_mode: 'all_photos') # rubocop:disable Rails/SkipsModelValidations
        album.regenerate_share_token!
      end

      let(:mode) { 'off' }

      it 'keeps the existing token (so turning it back on reuses the same link)' do
        existing_token = album.share_token

        post_mutation
        json = response.parsed_body

        expect(json.dig('data', 'setAlbumShareMode', 'shareMode')).to eq('off')
        expect(album.reload.share_token).to eq(existing_token)
      end
    end

    context 'with an invalid mode' do
      let(:mode) { 'everyone' }

      it 'returns a validation error' do
        post_mutation
        json = response.parsed_body

        expect(json['errors'].first['message']).to eq('Invalid share mode')
        expect(album.reload.share_mode).to eq('off')
      end
    end
  end

  context 'when logged in as an admin (not the owner)' do
    before { sign_in(create(:user, admin: true)) }

    it 'allows setting the share mode' do
      post_mutation
      json = response.parsed_body

      expect(json.dig('data', 'setAlbumShareMode', 'shareMode')).to eq('all_photos')
    end
  end
end
