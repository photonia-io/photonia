# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumPrivacy Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }
  let(:new_privacy) { 'private' }

  let(:update_photos) { false }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumPrivacy(
          id: "#{album.slug}",
          privacy: "#{new_privacy}",
          updatePhotos: #{update_photos}
        ) {
          album {
            id
            privacy
          }
          photosUpdatedCount
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
    it 'returns NOT_FOUND error and nulls setAlbumPrivacy' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['setAlbumPrivacy'])
      expect(json.dig('data', 'setAlbumPrivacy')).to be_nil
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

      expect(data['album']).to include(
        'id' => album.slug,
        'privacy' => 'private'
      )
      expect(data['photosUpdatedCount']).to eq(0)
      expect(album.reload.privacy).to eq('private')
    end

    context 'when setting privacy to friends_and_family' do
      let(:new_privacy) { 'friends_and_family' }

      it 'persists the mapped enum and returns the enum key in GraphQL' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data['album']).to include(
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

        expect(data['album']).to include(
          'id' => album.slug,
          'privacy' => 'public'
        )
        expect(album.reload.privacy).to eq('public')
      end
    end

    context 'when changing album from public to private with updatePhotos flag' do
      let(:update_photos) { true }
      let(:new_privacy) { 'private' }
      let!(:photo1) { create(:photo, user: album.user, privacy: 'public') }
      let!(:photo2) { create(:photo, user: album.user, privacy: 'public') }
      let!(:photo3) { create(:photo, user: album.user, privacy: 'private') }

      before do
        album.update(privacy: 'public')
        album.photos << photo1
        album.photos << photo2
        album.photos << photo3
      end

      it 'sets all contained photos to private' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data['album']['privacy']).to eq('private')
        expect(data['photosUpdatedCount']).to eq(3)

        expect(photo1.reload.privacy).to eq('private')
        expect(photo2.reload.privacy).to eq('private')
        expect(photo3.reload.privacy).to eq('private')
      end
    end

    context 'when changing album from public to private without updatePhotos flag' do
      let(:update_photos) { false }
      let(:new_privacy) { 'private' }
      let!(:photo1) { create(:photo, user: album.user, privacy: 'public') }
      let!(:photo2) { create(:photo, user: album.user, privacy: 'public') }

      before do
        album.update(privacy: 'public')
        album.photos << photo1
        album.photos << photo2
      end

      it 'does not update photo privacy' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data['album']['privacy']).to eq('private')
        expect(data['photosUpdatedCount']).to eq(0)

        expect(photo1.reload.privacy).to eq('public')
        expect(photo2.reload.privacy).to eq('public')
      end
    end

    context 'when changing album from private to public with updatePhotos flag' do
      let(:update_photos) { true }
      let(:new_privacy) { 'public' }
      let!(:photo1) { create(:photo, user: album.user, privacy: 'private') }
      let!(:photo2) { create(:photo, user: album.user, privacy: 'private') }

      before do
        album.update(privacy: 'private')
        album.photos << photo1
        album.photos << photo2
      end

      it 'does not update photo privacy (photos remain private)' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setAlbumPrivacy']

        expect(data['album']['privacy']).to eq('public')
        expect(data['photosUpdatedCount']).to eq(0)

        expect(photo1.reload.privacy).to eq('private')
        expect(photo2.reload.privacy).to eq('private')
      end
    end
  end
end
