# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FlickrUserType currentUserHasClaim field', type: :request do
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
              isClaimed
              currentUserHasClaim
            }
          }
        }
      }
    GQL
  end

  context 'when user is not logged in' do
    it 'returns false for currentUserHasClaim' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(false)
      expect(flickr_user_data['isClaimed']).to eq(false)
    end
  end

  context 'when user is logged in but has no claim' do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it 'returns false for currentUserHasClaim' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(false)
      expect(flickr_user_data['isClaimed']).to eq(false)
    end
  end

  context 'when user has a pending claim' do
    let(:user) { create(:user) }
    let!(:pending_claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user, status: 'pending') }

    before { sign_in(user) }

    it 'returns true for currentUserHasClaim' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(true)
      expect(flickr_user_data['isClaimed']).to eq(false)
    end
  end

  context 'when user has an approved claim' do
    let(:user) { create(:user) }
    let!(:approved_claim) { create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user) }

    before { sign_in(user) }

    it 'returns true for currentUserHasClaim and isClaimed' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(true)
      expect(flickr_user_data['isClaimed']).to eq(true)
    end
  end

  context 'when user has a denied claim' do
    let(:user) { create(:user) }
    let!(:denied_claim) { create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user) }

    before { sign_in(user) }

    it 'returns false for currentUserHasClaim (denied claims do not count)' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(false)
      expect(flickr_user_data['isClaimed']).to eq(false)
    end
  end

  context 'when different user has an approved claim' do
    let(:claiming_user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:approved_claim) { create(:flickr_user_claim, :approved, user: claiming_user, flickr_user: flickr_user) }

    before { sign_in(other_user) }

    it 'returns false for currentUserHasClaim but true for isClaimed' do
      post_query
      flickr_user_data = data_dig(response, 'photo', 'comments', 0, 'flickrUser')
      
      expect(flickr_user_data['currentUserHasClaim']).to eq(false)
      expect(flickr_user_data['isClaimed']).to eq(true)
    end
  end
end
