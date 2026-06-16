# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requestAutomaticFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  def build_query(nsid)
    <<~GQL
      mutation {
        requestAutomaticFlickrClaim(
          flickrUserNsid: "#{nsid}"
        ) {
          claim {
            id
            claimType
            status
            verificationCode
            user { id }
            flickrUser { nsid, username }
          }
          errors
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    let(:query) { build_query('any-nsid') }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestAutomaticFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('You must be signed in')
    end
  end

  context 'when the flickr user is not found' do
    let(:user) { create(:user) }
    let(:query) { build_query('non-existent') }

    before { sign_in(user) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestAutomaticFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('Flickr user not found')
    end
  end

  context 'when the flickr user is already claimed' do
    let(:user) { create(:user) }
    let(:claimer) { create(:user) }
    let(:flickr_user) { create(:flickr_user, claimed_by_user_id: claimer.id) }
    let(:query) { build_query(flickr_user.nsid) }

    before { sign_in(user) }

    it 'returns error payload and no claim' do
      post_mutation
      payload = data_dig(response, 'requestAutomaticFlickrClaim')

      expect(payload['claim']).to be_nil
      expect(payload['errors']).to include('This Flickr user has already been claimed')
    end
  end

  context 'when a pending claim by the same user already exists' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let!(:existing_claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user, status: 'pending') }
    let(:query) { build_query(flickr_user.nsid) }

    before { sign_in(user) }

    it 'returns the existing pending claim and no errors' do
      post_mutation
      payload = data_dig(response, 'requestAutomaticFlickrClaim')

      expect(payload['errors']).to eq([])
      claim = payload['claim']
      expect(claim['id']).to eq(existing_claim.id.to_s)
      expect(claim['status']).to eq('pending')
      expect(claim['claimType']).to eq('automatic')
      expect(claim['verificationCode']).to be_present
      expect(claim.dig('user', 'id')).to eq(user.slug)
      expect(claim.dig('flickrUser', 'nsid')).to eq(flickr_user.nsid)
    end
  end

  context 'when creating a new automatic claim' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:query) { build_query(flickr_user.nsid) }

    before { sign_in(user) }

    it 'creates a pending automatic claim and returns it with no errors' do
      post_mutation
      payload = data_dig(response, 'requestAutomaticFlickrClaim')

      expect(payload['errors']).to eq([])

      claim = payload['claim']
      expect(claim['id']).to be_present
      expect(claim['status']).to eq('pending')
      expect(claim['claimType']).to eq('automatic')
      expect(claim['verificationCode']).to be_present
      expect(claim.dig('user', 'id')).to eq(user.slug)
      expect(claim.dig('flickrUser', 'nsid')).to eq(flickr_user.nsid)
    end
  end
end
