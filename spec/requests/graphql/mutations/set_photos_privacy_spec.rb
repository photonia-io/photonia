# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setPhotosPrivacy Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:user) { create(:user) }
  let!(:photo1) { create(:photo, user: user, privacy: 'public') }
  let!(:photo2) { create(:photo, user: user, privacy: 'public') }
  let!(:photo3) { create(:photo, user: user, privacy: 'private') }
  let(:photo_ids) { [photo1.slug, photo2.slug] }
  let(:new_privacy) { 'private' }

  let(:query) do
    <<~GQL
      mutation {
        setPhotosPrivacy(
          photoIds: #{photo_ids.to_json},
          privacy: "#{new_privacy}"
        ) {
          photos {
            id
            privacy
          }
          errors
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    it 'updates the privacy of multiple photos' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setPhotosPrivacy']

      expect(data['errors']).to be_empty
      expect(data['photos'].size).to eq(2)
      expect(data['photos'].map { |p| p['privacy'] }).to all(eq('private'))

      expect(photo1.reload.privacy).to eq('private')
      expect(photo2.reload.privacy).to eq('private')
    end

    context 'when setting privacy to friends_and_family' do
      let(:new_privacy) { 'friends_and_family' }

      it 'updates the privacy correctly' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotosPrivacy']

        expect(data['errors']).to be_empty
        expect(data['photos'].map { |p| p['privacy'] }).to all(eq('friends_and_family'))
        expect(photo1.reload.privacy).to eq('friends_and_family')
      end
    end

    context 'when providing an invalid privacy value' do
      let(:new_privacy) { 'invalid_value' }

      it 'returns an error' do
        post_mutation
        json = response.parsed_body
        errors = json['errors'].first

        expect(errors['message']).to eq('Invalid privacy value')
      end
    end

    context 'when trying to update photos from another user' do
      let(:other_user) { create(:user) }
      let!(:other_photo) { create(:photo, user: other_user, privacy: 'public') }
      let(:photo_ids) { [photo1.slug, other_photo.slug] }

      it 'only updates authorized photos and returns errors for unauthorized ones' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotosPrivacy']

        expect(data['errors'].size).to eq(1)
        expect(data['errors'].first).to include("Not authorized")
        expect(photo1.reload.privacy).to eq('private')
        expect(other_photo.reload.privacy).to eq('public')
      end
    end

    context 'when some photo IDs are not found' do
      let(:photo_ids) { [photo1.slug, 'nonexistent-slug'] }

      it 'updates the found photos and ignores missing ones' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotosPrivacy']

        expect(data['photos'].size).to eq(1)
        expect(data['photos'].first['id']).to eq(photo1.slug)
        expect(photo1.reload.privacy).to eq('private')
      end
    end
  end
end
