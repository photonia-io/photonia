# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requestManualFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  def build_query(nsid, reason: nil)
    reason_fragment = reason.nil? ? '' : %(, reason: "#{reason}")
    <<~GQL
      mutation {
        requestManualFlickrClaim(
          flickrUserNsid: "#{nsid}"#{reason_fragment}
        ) {
          claim {
            id
            claimType
            status
            reason
            user { id }
            flickrUser { nsid, username }
          }
          errors
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    let(:query) { build_query('any-nsid', reason: 'Lost access to my account') }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestManualFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('You must be signed in')
    end
  end

  context 'when the flickr user is not found' do
    let(:user) { create(:user) }
    let(:query) { build_query('non-existent', reason: 'Lost access') }

    before { sign_in(user) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestManualFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Flickr user not found')
    end
  end

  context 'when the flickr user is already claimed' do
    let(:user) { create(:user) }
    let(:claimer) { create(:user) }
    let(:flickr_user) { create(:flickr_user, claimed_by_user_id: claimer.id) }
    let(:query) { build_query(flickr_user.nsid, reason: 'Ownership dispute') }

    before { sign_in(user) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestManualFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('This Flickr user has already been claimed')
    end
  end

  context 'when a pending claim by the same user already exists' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let!(:existing_claim) { create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user, status: 'pending') }
    let(:query) { build_query(flickr_user.nsid, reason: 'Lost password') }

    before { sign_in(user) }

    it 'returns the existing pending claim and no errors' do
      post_mutation
      payload = data_dig(response, 'requestManualFlickrClaim')

      expect(payload['errors']).to eq([])
      claim = payload['claim']
      expect(claim['id']).to eq(existing_claim.id.to_s)
      expect(claim['status']).to eq('pending')
      expect(claim['claimType']).to eq('manual')
      # Reason might be present depending on factory; ensure it’s not blowing up
      expect(claim.dig('user', 'id')).to eq(user.slug)
      expect(claim.dig('flickrUser', 'nsid')).to eq(flickr_user.nsid)
    end
  end

  context 'when creating a new manual claim' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:reason) { 'Lost access to my Flickr account' }
    let(:query) { build_query(flickr_user.nsid, reason:) }

    before do
      sign_in(user)
      # Ensure there is at least one admin so the service will try to email admins
      create(:user, admin: true)
      allow(AdminMailer).to receive_message_chain(:with, :flickr_claim_request, :deliver_later)
    end

    it 'creates a pending manual claim and returns it with no errors' do
      post_mutation
      payload = data_dig(response, 'requestManualFlickrClaim')

      expect(payload['errors']).to eq([])

      claim = payload['claim']
      expect(claim['id']).to be_present
      expect(claim['status']).to eq('pending')
      expect(claim['claimType']).to eq('manual')
      expect(claim['reason']).to eq(reason)
      expect(claim.dig('user', 'id')).to eq(user.slug)
      expect(claim.dig('flickrUser', 'nsid')).to eq(flickr_user.nsid)

      # Email notification was triggered
      expect(AdminMailer).to have_received(:with)
    end
  end
end
