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

    before do
      flickr_user.update!(claimed_by_user: claiming_user)
      sign_in(other_user)
    end

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

    before do
      flickr_user.update!(claimed_by_user: user)
      sign_in(user)
    end

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

    before do
      other_flickr_user.update!(claimed_by_user: user)
      sign_in(user)
    end

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

  # The claimant is a full User (email, names); exposing it on a public type would leak it
  # to anyone viewing a photo's comments.
  context 'when claimedByUser is selected' do
    let(:query) do
      <<~GQL
        query {
          photo(id: #{photo.slug}) {
            comments {
              flickrUser { claimedByUser { id } }
            }
          }
        }
      GQL
    end

    it 'is not a field on FlickrUserType' do
      post_query

      expect(first_error_message(response)).to include("Field 'claimedByUser' doesn't exist on type 'FlickrUser'")
    end
  end

  # PhotoQuery precomputes context[:user_has_claim] to avoid an N+1 across a photo's comments.
  # Querying `claimable` through a path that doesn't go through that lookahead (myFlickrClaims'
  # flickrUser field) must still reflect the user's real claim state instead of defaulting to
  # "claimable" just because the context key was never set.
  context 'when claimable is queried through a path that does not precompute context[:user_has_claim]' do
    let(:user) { create(:user) }
    let!(:pending_claim) { create(:flickr_user_claim, user: user, status: 'pending') }
    let(:query) do
      <<~GQL
        query {
          myFlickrClaims {
            flickrUser { nsid, claimable }
          }
        }
      GQL
    end

    before { sign_in(user) }

    it 'still returns false instead of defaulting to claimable' do
      post_query
      flickr_user_data = data_dig(response, 'myFlickrClaims').first['flickrUser']

      expect(flickr_user_data['nsid']).to eq(pending_claim.flickr_user.nsid)
      expect(flickr_user_data['claimable']).to eq(false)
    end
  end
end
