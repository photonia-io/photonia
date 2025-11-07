# frozen_string_literal: true

require 'rails_helper'

describe 'pendingFlickrClaims Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:flickr_user1) { create(:flickr_user) }
  let(:flickr_user2) { create(:flickr_user) }
  let(:flickr_user3) { create(:flickr_user) }
  let(:flickr_user4) { create(:flickr_user) }

  let!(:pending_claim1) do
    create(:flickr_user_claim, user: user, flickr_user: flickr_user1, status: 'pending')
  end
  let!(:pending_claim2) do
    create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user2, status: 'pending')
  end
  let!(:approved_claim) do
    create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user3)
  end
  let!(:denied_claim) do
    create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user4)
  end

  let(:query) do
    <<~GQL
      query {
        pendingFlickrClaims {
          id
          claimType
          status
          verificationCode
          reason
          createdAt
          user {
            id
            displayName
            email
          }
          flickrUser {
            id
            username
            realName
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns an empty array' do
      post_query

      json = response.parsed_body

      expect(json['data']['pendingFlickrClaims']).to eq([])
    end
  end

  context 'when a regular user is logged in' do
    before do
      sign_in(user)
    end

    it 'returns an empty array due to authorization failure' do
      post_query

      json = response.parsed_body

      expect(json['data']['pendingFlickrClaims']).to eq([])
    end
  end

  context 'when an admin user is logged in' do
    before do
      sign_in(admin_user)
    end

    it 'returns only pending claims' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']

      expect(claims.size).to eq(2)

      claim_ids = claims.map { |c| c['id'].to_i }
      expect(claim_ids).to contain_exactly(pending_claim1.id, pending_claim2.id)

      # Verify all returned claims have pending status
      claims.each do |claim|
        expect(claim['status']).to eq('pending')
      end
    end

    it 'orders claims by created_at descending' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']

      # Most recent claim should be first
      expect(claims[0]['id']).to eq(pending_claim2.id.to_s)
      expect(claims[1]['id']).to eq(pending_claim1.id.to_s)
    end

    it 'does not include approved or denied claims' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']
      claim_ids = claims.map { |c| c['id'].to_i }

      expect(claim_ids).not_to include(approved_claim.id)
      expect(claim_ids).not_to include(denied_claim.id)
    end

    it 'includes user information for each claim' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']

      claims.each do |claim|
        expect(claim['user']).to be_present
        expect(claim['user']['id']).to be_present
        expect(claim['user']['displayName']).to be_present
        expect(claim['user']['email']).to be_present
      end
    end

    it 'includes flickr user information for each claim' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']

      claims.each do |claim|
        expect(claim['flickrUser']).to be_present
        expect(claim['flickrUser']['id']).to be_present
        expect(claim['flickrUser']['username']).to be_present
      end
    end

    it 'includes verification code for automatic claims' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']
      automatic_claim = claims.find { |c| c['id'] == pending_claim1.id.to_s }

      expect(automatic_claim['claimType']).to eq('automatic')
      expect(automatic_claim['verificationCode']).to be_present
    end

    it 'includes reason for manual claims' do
      post_query

      json = response.parsed_body
      claims = json['data']['pendingFlickrClaims']
      manual_claim = claims.find { |c| c['id'] == pending_claim2.id.to_s }

      expect(manual_claim['claimType']).to eq('manual')
      expect(manual_claim['reason']).to be_present
    end
  end

  context 'when there are no pending claims' do
    before do
      sign_in(admin_user)
      # Update all claims to non-pending status
      FlickrUserClaim.pending.each(&:approve!)
    end

    it 'returns an empty array' do
      post_query

      json = response.parsed_body

      expect(json['data']['pendingFlickrClaims']).to eq([])
    end
  end
end
