# frozen_string_literal: true

require 'rails_helper'

describe 'updateAlbumDescription Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:title) { 'Test title' }
  let(:description) { 'Test description' }
  let(:album) { create(:album, title: title, description: description) }

  let(:new_description) { 'New test description' }

  let(:query) do
    <<~GQL
      mutation {
        updateAlbumDescription(
          id: "#{album.slug}"
          description: "#{new_description}"
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
    it 'returns NOT_FOUND error and nulls updateAlbumDescription' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['updateAlbumDescription'])
      expect(json.dig('data', 'updateAlbumDescription')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(album.user)
    end

    it 'updates the album description' do
      post_mutation
      json = response.parsed_body
      data = json['data']['updateAlbumDescription']

      expect(data).to include(
        'id' => album.slug,
        'title' => title,
        'description' => new_description
      )
    end

    context 'when updating to an empty description' do
      let(:new_description) { '' }

      it 'updates the album description' do
        post_mutation
        json = response.parsed_body
        data = json['data']['updateAlbumDescription']

        expect(data).to include(
          'id' => album.slug,
          'title' => title,
          'description' => new_description
        )
      end
    end
  end
end
