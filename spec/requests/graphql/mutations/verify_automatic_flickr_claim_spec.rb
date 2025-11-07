# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'verifyAutomaticFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  def build_query(claim_id)
    <<~GQL
      mutation {
        verifyAutomaticFlickrClaim(
          claimId: "#{claim_id}"
        ) {
          success
          errors
          claim {
            id
            status
            verifiedAt
            approvedAt
            flickrUser {
              nsid
              username
            }
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    let(:query) { build_query('999999') }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('You must be signed in')
    end
  end

  context 'when the claim is not found' do
    let(:user) { create(:user) }
    let(:query) { build_query('999999') }

    before { sign_in(user) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Claim not found')
    end
  end

  context 'when the user does not own the claim' do
    let(:owner) { create(:user) }
    let(:stranger) { create(:user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: owner) }
    let(:query) { build_query(claim.id) }

    before { sign_in(stranger) }

    it 'returns not authorized error and no claim' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Not authorized to verify this claim')
    end
  end

  context 'when the claim is manual (invalid type) but owned by the user' do
    let(:user) { create(:user) }
    let(:claim) { create(:flickr_user_claim, :manual, user: user) }
    let(:query) { build_query(claim.id) }

    before { sign_in(user) }

    it 'returns error from service and leaves the claim pending' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['errors'].first).to eq('Invalid claim type')
      expect(payload['claim']['id']).to eq(claim.id.to_s)
      expect(payload['claim']['status']).to eq('pending')
      expect(claim.reload.status).to eq('pending')
    end
  end

  context 'when code is missing from profile description' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }
    let(:query) { build_query(claim.id) }

    before do
      sign_in(user)
      allow(FlickrAPIService).to receive(:profile_get_profile_description)
        .with(flickr_user.nsid)
        .and_return('no verification code here')
    end

    it 'returns error and keeps the claim pending' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['errors'].first).to include('Verification code not found')
      expect(payload['claim']['id']).to eq(claim.id.to_s)
      expect(payload['claim']['status']).to eq('pending')
      expect(claim.reload.status).to eq('pending')
    end
  end

  context 'when profile cannot be fetched' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }
    let(:query) { build_query(claim.id) }

    before do
      sign_in(user)
      allow(FlickrAPIService).to receive(:profile_get_profile_description)
        .with(flickr_user.nsid)
        .and_return(nil)
    end

    it 'returns error and keeps the claim pending' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['errors'].first).to include('Unable to fetch Flickr profile')
      expect(claim.reload.status).to eq('pending')
    end
  end

  context 'when verification succeeds' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }
    let(:query) { build_query(claim.id) }

    before do
      sign_in(user)
      allow(FlickrAPIService).to receive(:profile_get_profile_description)
        .with(flickr_user.nsid)
        .and_return("some text #{claim.verification_code} more text")
    end

    it 'returns success and approves the claim' do
      post_mutation
      payload = data_dig(response, 'verifyAutomaticFlickrClaim')
      expect(payload['errors']).to eq([])
      expect(payload['success']).to be(true)

      claim_payload = payload['claim']
      expect(claim_payload['id']).to eq(claim.id.to_s)
      expect(claim_payload['status']).to eq('approved')
      expect(claim_payload['verifiedAt']).to be_present
      expect(claim_payload['approvedAt']).to be_present

      expect(claim.reload.status).to eq('approved')
      expect(claim.verified_at).to be_present
      expect(claim.approved_at).to be_present
      expect(flickr_user.reload.claimed_by_user).to eq(user)
    end
  end
end
