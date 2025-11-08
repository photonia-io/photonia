# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FlickrUserType claimable field', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, image_data: TestData.image_data) }
  let(:flickr_user) { create(:flickr_user) }
  let!(:comment) { create(:comment, flickr_user: flickr_user, commentable: photo) }

  let(:query) do
    <<~GQL
      query {
        photo(id: #{photo.slug}) {
          comments {
            flickrUser {
              nsid
              claimable
            }
          }
        }
      }
    GQL
  end

  context 'when user is not logged in' do
    it 'returns true for claimable (unclaimed flickr user)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(true)
    end
  end

  context 'when user is logged in but has no claim' do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it 'returns true for claimable' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(true)
    end
  end

  context 'when flickr user is already claimed by someone' do
    let(:claiming_user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:approved_claim) { create(:flickr_user_claim, :approved, user: claiming_user, flickr_user: flickr_user) }

    before { sign_in(other_user) }

    it 'returns false for claimable (flickr user already claimed)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end

  context 'when user has a pending claim on this flickr user' do
    let(:user) { create(:user) }
    let!(:pending_claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user, status: 'pending') }

    before { sign_in(user) }

    it 'returns false for claimable (user has pending claim)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end

  context 'when user has a pending claim on a different flickr user' do
    let(:user) { create(:user) }
    let(:other_flickr_user) { create(:flickr_user) }
    let!(:pending_claim) { create(:flickr_user_claim, user: user, flickr_user: other_flickr_user, status: 'pending') }

    before { sign_in(user) }

    it 'returns false for claimable (user has pending claim on ANY flickr user)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end

  context 'when user has an approved claim on this flickr user' do
    let(:user) { create(:user) }
    let!(:approved_claim) { create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user) }

    before { sign_in(user) }

    it 'returns false for claimable (flickr user already claimed and user has approved claim)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end

  context 'when user has an approved claim on a different flickr user' do
    let(:user) { create(:user) }
    let(:other_flickr_user) { create(:flickr_user) }
    let!(:approved_claim) { create(:flickr_user_claim, :approved, user: user, flickr_user: other_flickr_user) }

    before { sign_in(user) }

    it 'returns false for claimable (user has approved claim on ANY flickr user)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end

  context 'when user has a denied claim' do
    let(:user) { create(:user) }
    let!(:denied_claim) { create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user) }

    before { sign_in(user) }

    it 'returns true for claimable (denied claims do not count)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['claimable']).to eq(true)
    end
  end
end
