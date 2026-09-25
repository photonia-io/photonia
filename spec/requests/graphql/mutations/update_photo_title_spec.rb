# frozen_string_literal: true

require 'rails_helper'

describe 'updatePhotoTitle Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:title) { 'Test title' }
  let(:description) { 'Test description' }
  let(:photo) { create(:photo, title: title, description: description) }

  let(:new_title) { 'New test title' }

  let(:query) do
    <<~GQL
      mutation {
        updatePhotoTitle(
          id: "#{photo.id}"
          title: "#{new_title}"
        ) {
          id
          title
          description
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls updatePhotoTitle' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['updatePhotoTitle'])
      expect(json.dig('data', 'updatePhotoTitle')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(photo.user)
    end

    it 'updates the photo title' do
      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['updatePhotoTitle']

      expect(data).to include(
        'id' => photo.slug,
        'title' => new_title,
        'description' => description
      )
    end

    context 'when updating to an empty title' do
      let(:new_title) { '' }

      it 'updates the photo title' do
        post_mutation
        json = JSON.parse(response.body)
        data = json['data']['updatePhotoTitle']

        expect(data).to include(
          'id' => photo.slug,
          'title' => new_title,
          'description' => description
        )
      end

      context 'when the description is also empty' do
        let(:description) { '' }

        it 'raises an error' do
          post_mutation
          json = JSON.parse(response.body)
          errors = json['errors'].first

          expect(errors['message']).to eq('Either title or description is required')
        end
      end
    end
  end

  context 'when the photo is private' do
    include_context 'with auth actors'

    let(:photo) { create(:photo, title: title, description: description, user: owner, privacy: :private) }

    it 'lets the owner update it' do
      sign_in(owner)
      post_mutation
      data = response.parsed_body['data']['updatePhotoTitle']
      expect(data).to include('id' => photo.slug, 'title' => new_title)
    end

    it 'lets an admin update it' do
      sign_in(admin)
      post_mutation
      data = response.parsed_body['data']['updatePhotoTitle']
      expect(data).to include('id' => photo.slug, 'title' => new_title)
    end

    it 'returns NOT_FOUND for a stranger' do
      sign_in(stranger)
      post_mutation
      err = response.parsed_body['errors']&.first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end
end
