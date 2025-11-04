# frozen_string_literal: true

require 'rails_helper'

# Access control by role for photo detail
describe 'photo access control by role (detail)', :authorization do
  include Devise::Test::IntegrationHelpers

  def query_for(id)
    <<~GQL
      query {
        photo(id: #{id}) {
          id
        }
      }
    GQL
  end

  include_context 'auth actors'

  let!(:public_photo)  { create(:photo, user: owner) }
  let!(:private_photo) { create(:photo, user: owner, privacy: :private) }

  context 'as a visitor' do
    it 'can fetch the public photo' do
      post '/graphql', params: { query: query_for(public_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(public_photo.slug.to_s)
    end

    it 'returns NOT_FOUND error and nulls the photo' do
      post '/graphql', params: { query: query_for(private_photo.slug) }
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['photo'])
      expect(json.dig('data', 'photo')).to be_nil
    end
  end

  context 'as a logged-in non-owner' do
    before { sign_in(stranger) }

    it 'can fetch the public photo' do
      post '/graphql', params: { query: query_for(public_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(public_photo.slug.to_s)
    end

    it 'returns NOT_FOUND error and nulls the photo' do
      post '/graphql', params: { query: query_for(private_photo.slug) }
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['photo'])
      expect(json.dig('data', 'photo')).to be_nil
    end
  end

  context 'as the owner' do
    before { sign_in(owner) }

    it 'can fetch the public photo' do
      post '/graphql', params: { query: query_for(public_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(public_photo.slug.to_s)
    end

    it 'can fetch the private photo' do
      post '/graphql', params: { query: query_for(private_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(private_photo.slug.to_s)
    end
  end

  context 'as an admin' do
    before { sign_in(admin) }

    it 'can fetch the public photo' do
      post '/graphql', params: { query: query_for(public_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(public_photo.slug.to_s)
    end

    it 'can fetch the private photo' do
      post '/graphql', params: { query: query_for(private_photo.slug) }
      data = response.parsed_body['data']['photo']
      expect(data['id']).to eq(private_photo.slug.to_s)
    end
  end
end
