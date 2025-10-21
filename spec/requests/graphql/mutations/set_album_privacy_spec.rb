# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumPrivacy Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }
  let(:new_privacy) { 'private' }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumPrivacy(
          id: "#{album.slug}",
          privacy: "#{new_privacy}"
        ) {
          id
          privacy
        }
      }
    GQL
  end

  context 'when the album is not found' do
    before do
      album.destroy
    end

    it 'returns an error' do
      post_mutation
      json = response.parsed_body
      errors = json['errors'].first

      expect(errors['message']).to eq('Album not found')
    end
  end

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(album.user)
    end

    it 'updates the album privacy to private' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setAlbumPrivacy']

      expect(data).to include(
        'id' => album.slug,
        'privacy' => 'private'
      )
      expect(album.reload.privacy).to eq('private')
    end

    context 'when setting privacy to friends_and_family' do
      let(:new_privacy) { 'friends_and_family' }

      it 'persists the mapped enum and returns the enum key in GraphQL' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data).to include(
          'id' => album.slug,
          # GraphQL returns the Rails enum key
          'privacy' => 'friends_and_family'
        )
        # Rails enum attribute returns the enum key
        expect(album.reload.privacy).to eq('friends_and_family')
      end
    end

    context 'when providing an invalid privacy value' do
      let(:new_privacy) { 'invalid_value' }

      it 'returns a validation error' do
        post_mutation
        json = response.parsed_body
        errors = json['errors'].first

        expect(errors['message']).to eq('Invalid privacy value')
      end
    end

    context 'when the album is private' do
      let(:new_privacy) { 'public' }

      before do
        album.update(privacy: 'private')
      end

      it 'allows changing privacy to public' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data).to include(
          'id' => album.slug,
          'privacy' => 'public'
        )
        expect(album.reload.privacy).to eq('public')
      end
    end
  end
end
