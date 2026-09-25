# frozen_string_literal: true

require 'rails_helper'

describe 'deletePhoto Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:photo) { create(:photo, user: owner) }

  let(:query) do
    <<~GQL
      mutation {
        deletePhoto(id: "#{photo.slug}") {
          id
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls deletePhoto' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['deletePhoto'])
      expect(json.dig('data', 'deletePhoto')).to be_nil
    end
  end

  context 'when the owner is logged in' do
    before do
      sign_in(owner)
      photo # force creation before the mutation runs, or the expected count delta is masked
    end

    it 'deletes the photo' do
      expect { post_mutation }.to change(Photo.unscoped, :count).by(-1)
      data = response.parsed_body['data']['deletePhoto']
      expect(data['id']).to eq(photo.slug)
    end

    context 'when the photo is private' do
      let(:photo) { create(:photo, user: owner, privacy: :private) }

      it 'deletes the photo' do
        expect { post_mutation }.to change(Photo.unscoped, :count).by(-1)
      end
    end

    context 'when the private photo belongs to a private album' do
      let(:photo) { create(:photo, user: owner, privacy: :private) }
      let(:album) { create(:album, user: owner, privacy: :private) }

      before do
        album.photos << photo
        album.maintenance # AlbumsPhoto doesn't run maintenance on create; the caller must
      end

      it 'updates the album photo count' do
        expect { post_mutation }.to change { album.reload.photos_count }.by(-1)
      end
    end
  end

  context 'when a stranger tries to delete a private photo' do
    let(:photo) { create(:photo, user: owner, privacy: :private) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND error and nulls deletePhoto' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'deletePhoto')).to be_nil
      expect(Photo.unscoped).to include(photo)
    end
  end
end
