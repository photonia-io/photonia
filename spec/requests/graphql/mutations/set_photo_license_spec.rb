# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setPhotoLicense Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, image_data: TestData.image_data, license: 'All Rights Reserved') }
  let(:new_license) { 'CC BY 4.0' }
  let(:license_arg) { new_license.nil? ? 'null' : "\"#{new_license}\"" }

  let(:query) do
    <<~GQL
      mutation {
        setPhotoLicense(
          id: "#{photo.slug}",
          license: #{license_arg}
        ) {
          id
          license
        }
      }
    GQL
  end

  context 'when the photo is not found' do
    before do
      photo.destroy
    end

    it 'returns an error' do
      post_mutation
      json = response.parsed_body
      errors = json['errors'].first

      expect(errors['message']).to eq('Photo not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls setPhotoLicense' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['setPhotoLicense'])
      expect(json.dig('data', 'setPhotoLicense')).to be_nil
    end
  end

  context 'when a different user is logged in' do
    before do
      sign_in(create(:user))
    end

    it 'returns NOT_FOUND error and nulls setPhotoLicense' do
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

    it 'updates the photo license' do
      post_mutation
      json = response.parsed_body
      data = json['data']['setPhotoLicense']

      expect(data).to include(
        'id' => photo.slug,
        'license' => 'CC BY 4.0'
      )
      expect(photo.reload.license).to eq('CC BY 4.0')
    end

    context 'when the photo is private' do
      before do
        photo.update(privacy: 'private')
      end

      it 'allows changing the license' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotoLicense']

        expect(data).to include(
          'id' => photo.slug,
          'license' => 'CC BY 4.0'
        )
        expect(photo.reload.license).to eq('CC BY 4.0')
      end
    end

    context 'when providing an invalid license value' do
      let(:new_license) { 'Whatever I Want' }

      it 'returns a validation error and leaves the license unchanged' do
        post_mutation
        json = response.parsed_body
        errors = json['errors'].first

        expect(errors['message']).to eq('Invalid license value')
        expect(photo.reload.license).to eq('All Rights Reserved')
      end
    end

    context 'when clearing the license' do
      let(:new_license) { nil }

      it 'sets the license to nil' do
        post_mutation
        json = response.parsed_body
        data = json['data']['setPhotoLicense']

        expect(data).to include(
          'id' => photo.slug,
          'license' => nil
        )
        expect(photo.reload.license).to be_nil
      end
    end
  end

  context 'when an admin is logged in' do
    before do
      sign_in(create(:user, admin: true))
    end

    it "allows changing another user's photo license" do
      post_mutation
      json = response.parsed_body
      data = json['data']['setPhotoLicense']

      expect(data).to include(
        'id' => photo.slug,
        'license' => 'CC BY 4.0'
      )
      expect(photo.reload.license).to eq('CC BY 4.0')
    end
  end
end
