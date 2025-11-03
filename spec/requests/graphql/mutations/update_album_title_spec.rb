# frozen_string_literal: true

require 'rails_helper'

describe 'updateAlbumTitle Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:title) { 'Test title' }
  let(:description) { 'Test description' }
  let(:album) { create(:album, title: title, description: description) }

  let(:new_title) { 'New test title' }

  let(:query) do
    <<~GQL
      mutation {
        updateAlbumTitle(
          id: "#{album.slug}"
          title: "#{new_title}"
        ) {
          id
          title
          description
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
    it 'returns NOT_FOUND error and nulls updateAlbumTitle' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['updateAlbumTitle'])
      expect(json.dig('data', 'updateAlbumTitle')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(album.user)
    end

    it 'updates the album title' do
      post_mutation
      json = response.parsed_body
      data = json['data']['updateAlbumTitle']

      expect(data).to include(
        'id' => album.slug,
        'title' => new_title,
        'description' => description
      )
    end

    context 'when updating to an empty title' do
      let(:new_title) { '' }

      it 'returns an error' do
        post_mutation
        json = response.parsed_body
        errors = json['errors'].first

        expect(errors['message']).to eq("Title can't be blank")
      end
    end
  end
end
