# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'flickrUserClaim Query', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  def build_query(id)
    <<~GQL
      query {
        flickrUserClaim(id: "#{id}") {
          id
          status
          claimType
          verificationCode
          user { id }
          flickrUser { nsid, username }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    let(:claim) { create(:flickr_user_claim, :automatic) }
    let(:query) { build_query(claim.id) }

    it 'returns null' do
      post_query
      expect(data_dig(response, 'flickrUserClaim')).to be_nil
    end
  end

  context 'when the claim is not found' do
    let(:user) { create(:user) }
    let(:query) { build_query('999999') }

    before { sign_in(user) }

    it 'returns null' do
      post_query
      expect(data_dig(response, 'flickrUserClaim')).to be_nil
    end
  end

  context 'when the user is not the owner and not an admin' do
    let(:owner) { create(:user) }
    let(:stranger) { create(:user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: owner) }
    let(:query) { build_query(claim.id) }

    before { sign_in(stranger) }

    it 'returns null (not authorized)' do
      post_query
      expect(data_dig(response, 'flickrUserClaim')).to be_nil
    end
  end

  context 'when the user is the owner' do
    let(:owner) { create(:user) }
    let(:claim) { create(:flickr_user_claim, :automatic, user: owner) }
    let(:query) { build_query(claim.id) }

    before { sign_in(owner) }

    it 'returns the claim data' do
      post_query
      result = data_dig(response, 'flickrUserClaim')

      expect(result).to include(
        'id' => claim.id.to_s,
        'status' => claim.status,
        'claimType' => 'automatic'
      )
      expect(result['verificationCode']).to be_present
      expect(result.dig('user', 'id')).to eq(owner.slug)
      expect(result.dig('flickrUser', 'nsid')).to eq(claim.flickr_user.nsid)
    end
  end

  context 'when the user is an admin' do
    let(:admin) { create(:user, admin: true) }
    let(:claim) { create(:flickr_user_claim, :manual) }
    let(:query) { build_query(claim.id) }

    before { sign_in(admin) }

    it 'returns the claim data' do
      post_query
      result = data_dig(response, 'flickrUserClaim')

      expect(result).to include(
        'id' => claim.id.to_s,
        'status' => claim.status,
        'claimType' => 'manual'
      )
      expect(result.dig('user', 'id')).to eq(claim.user.slug)
      expect(result.dig('flickrUser', 'nsid')).to eq(claim.flickr_user.nsid)
    end
  end
end
