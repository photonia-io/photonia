# frozen_string_literal: true

require 'rails_helper'

describe 'myFlickrClaims Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:flickr_user1) { create(:flickr_user) }
  let(:flickr_user2) { create(:flickr_user) }
  let(:flickr_user3) { create(:flickr_user) }
  let!(:user_claim1) do
    create(:flickr_user_claim, user: user, flickr_user: flickr_user1, status: 'pending')
  end
  let!(:user_claim2) do
    create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user2)
  end
  let!(:user_claim3) do
    create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user3)
  end
  let!(:other_user_claim) do
    create(:flickr_user_claim, user: other_user, flickr_user: create(:flickr_user))
  end

  let(:query) do
    <<~GQL
      query {
        myFlickrClaims {
          id
          claimType
          status
          createdAt
          user {
            id
            displayName
          }
          flickrUser {
            id
            username
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns an empty array' do
      post_query

      json = response.parsed_body

      expect(json['data']['myFlickrClaims']).to eq([])
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    it 'returns all claims for the current user' do
      post_query

      json = response.parsed_body
      claims = json['data']['myFlickrClaims']

      expect(claims.size).to eq(3)

      # Should be ordered by created_at desc (most recent first)
      expect(claims[0]['id']).to eq(user_claim3.id.to_s)
      expect(claims[1]['id']).to eq(user_claim2.id.to_s)
      expect(claims[2]['id']).to eq(user_claim1.id.to_s)

      # Verify all claims belong to the current user
      claims.each do |claim|
        expect(claim['user']['id']).to eq(user.slug)
      end

      # Should not include other users' claims
      claim_ids = claims.map { |c| c['id'].to_i }
      expect(claim_ids).not_to include(other_user_claim.id)
    end

    it 'returns claims with all statuses' do
      post_query

      json = response.parsed_body
      claims = json['data']['myFlickrClaims']
      statuses = claims.map { |c| c['status'] }

      expect(statuses).to contain_exactly('pending', 'approved', 'denied')
    end

    it 'includes associated flickr user information' do
      post_query

      json = response.parsed_body
      claims = json['data']['myFlickrClaims']

      claims.each do |claim|
        expect(claim['flickrUser']).to be_present
        expect(claim['flickrUser']['id']).to be_present
        expect(claim['flickrUser']['username']).to be_present
      end
    end
  end

  context 'when the user has no claims' do
    let(:user_with_no_claims) { create(:user) }

    before do
      sign_in(user_with_no_claims)
    end

    it 'returns an empty array' do
      post_query

      json = response.parsed_body

      expect(json['data']['myFlickrClaims']).to eq([])
    end
  end
end
