# frozen_string_literal: true

require 'rails_helper'

describe 'deletePhotos Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:first_photo) { create(:photo, user: owner) }
  let(:second_photo) { create(:photo, user: owner) }

  let(:query) do
    <<~GQL
      mutation {
        deletePhotos(ids: ["#{first_photo.slug}", "#{second_photo.slug}"]) {
          id
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls deletePhotos' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['deletePhotos'])
      expect(json.dig('data', 'deletePhotos')).to be_nil
    end
  end

  context 'when the owner is logged in' do
    before do
      sign_in(owner)
      [first_photo, second_photo] # force creation before the mutation runs, or the expected count delta is masked
    end

    it 'deletes the photos' do
      expect { post_mutation }.to change(Photo.unscoped, :count).by(-2)
      data = response.parsed_body['data']['deletePhotos']
      expect(data.pluck('id')).to contain_exactly(first_photo.slug, second_photo.slug)
    end

    context 'when the photos are private and share a private album' do
      let(:first_photo) { create(:photo, user: owner, privacy: :private) }
      let(:second_photo) { create(:photo, user: owner, privacy: :private) }
      let(:album) { create(:album, user: owner, privacy: :private) }

      before do
        album.photos << first_photo
        album.photos << second_photo
        album.maintenance # AlbumsPhoto doesn't run maintenance on create; the caller must
      end

      it 'deletes both photos and updates the album photo count' do
        expect { post_mutation }.to change { album.reload.photos_count }.by(-2)
        expect(Photo.unscoped.where(id: [first_photo.id, second_photo.id])).to be_empty
      end
    end
  end

  context 'when a stranger tries to delete a private photo' do
    let(:first_photo) { create(:photo, user: owner, privacy: :private) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND error and nulls deletePhotos' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'deletePhotos')).to be_nil
      expect(Photo.unscoped).to include(first_photo)
    end
  end
end
