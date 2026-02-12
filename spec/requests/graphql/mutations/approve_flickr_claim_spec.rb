# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'approveFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  def build_query(claim_id)
    <<~GQL
      mutation {
        approveFlickrClaim(
          claimId: "#{claim_id}"
        ) {
          success
          errors
          claim {
            id
            status
            approvedAt
            deniedAt
            user { id }
            flickrUser { nsid }
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    let(:query) { build_query('999999') }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'approveFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('You must be signed in')
    end
  end

  context 'when the claim is not found' do
    let(:admin) { create(:user, admin: true) }
    let(:query) { build_query('999999') }

    before { sign_in(admin) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'approveFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Claim not found')
    end
  end

  context 'when the user is not an admin' do
    let(:user) { create(:user) }
    let(:claim) { create(:flickr_user_claim) }
    let(:query) { build_query(claim.id) }

    before { sign_in(user) }

    it 'returns not authorized error and no claim' do
      post_mutation
      payload = data_dig(response, 'approveFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Not authorized to approve claims')
    end
  end

  context 'when the claim is not pending' do
    let(:admin) { create(:user, admin: true) }
    let(:claim) { create(:flickr_user_claim, :approved) }
    let(:query) { build_query(claim.id) }

    before do
      sign_in(admin)
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_approved, :deliver_later)
    end

    it 'returns service error and includes the claim in payload' do
      post_mutation
      payload = data_dig(response, 'approveFlickrClaim')
      expect(payload['success']).to be(false)
      expect(payload['errors'].first).to eq('Claim is not pending')
      expect(payload['claim']['id']).to eq(claim.id.to_s)
    end
  end

  context 'when approval succeeds' do
    let(:admin) { create(:user, admin: true) }
    let(:claim) { create(:flickr_user_claim) } # pending by default
    let(:query) { build_query(claim.id) }

    before do
      sign_in(admin)
      # Prevent actual mail delivery
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_approved, :deliver_later)
    end

    it 'returns success and approves the claim' do
      post_mutation
      payload = data_dig(response, 'approveFlickrClaim')
      expect(payload['errors']).to eq([])
      expect(payload['success']).to be(true)

      claim_payload = payload['claim']
      expect(claim_payload['id']).to eq(claim.id.to_s)
      expect(claim_payload['status']).to eq('approved')
      expect(claim_payload['approvedAt']).to be_present
      expect(claim_payload['deniedAt']).to be_nil

      expect(claim.reload.status).to eq('approved')
      expect(claim.approved_at).to be_present
      # The service sets flickr_user.claimed_by_user to the claimer (claim.user)
      expect(claim.flickr_user.reload.claimed_by_user).to eq(claim.user)
    end
  end
end
