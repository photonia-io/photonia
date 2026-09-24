# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setPhotoPrivacy Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, image_data: TestData.image_data) }
  let(:new_privacy) { 'private' }

  let(:query) do
    <<~GQL
      mutation {
        setPhotoPrivacy(
          id: "#{photo.slug}",
          privacy: "#{new_privacy}"
        ) {
          id
          privacy
        }
      }
    GQL
  end

  context 'when the photo is not found' do
    before do
      sign_in(photo.user)
      photo.destroy
    end

    it 'returns the same NOT_FOUND error as an unauthorized photo' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'setPhotoPrivacy')).to be_nil
    end
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls setPhotoPrivacy' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['setPhotoPrivacy'])
      expect(json.dig('data', 'setPhotoPrivacy')).to be_nil
    end
  end

  context 'when a different user is logged in' do
    before do
      sign_in(create(:user))
    end

    it 'returns NOT_FOUND error and nulls setPhotoPrivacy' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when the owner is logged in' do
    before do
      sign_in(photo.user)
    end

    it 'updates the photo privacy to private' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setPhotoPrivacy']

      expect(data).to include(
        'id' => photo.slug,
        'privacy' => 'private'
      )
      expect(photo.reload.privacy).to eq('private')
    end

    context 'when setting privacy to friends_and_family' do
      let(:new_privacy) { 'friends_and_family' }

      it 'persists the mapped enum and returns the enum key in GraphQL' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotoPrivacy']

        expect(data).to include(
          'id' => photo.slug,
          # GraphQL returns the Rails enum key
          'privacy' => 'friends_and_family'
        )
        # Rails enum attribute returns the enum key
        expect(photo.reload.privacy).to eq('friends_and_family')
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

    context 'when the photo belongs to an album' do
      let!(:album) { create(:album, privacy: 'public') }

      before do
        album.photos << photo
        album.maintenance
      end

      it "refreshes the album's public photo count and cover" do
        expect(album.reload.public_photos_count).to eq(1)
        expect(album.public_cover_photo_id).to eq(photo.id)

        post_mutation

        expect(album.reload.public_photos_count).to eq(0)
        expect(album.public_cover_photo_id).to be_nil
      end
    end

    context 'when the photo is private' do
      let(:new_privacy) { 'public' }

      before do
        photo.update(privacy: 'private')
      end

      it 'allows changing privacy to public' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotoPrivacy']

        expect(data).to include(
          'id' => photo.slug,
          'privacy' => 'public'
        )
        expect(photo.reload.privacy).to eq('public')
      end
    end
  end

  context 'when an admin is logged in' do
    before do
      sign_in(create(:user, admin: true))
    end

    it 'allows changing another user\'s photo privacy' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setPhotoPrivacy']

      expect(data).to include(
        'id' => photo.slug,
        'privacy' => 'private'
      )
      expect(photo.reload.privacy).to eq('private')
    end
  end
end
