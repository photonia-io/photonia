# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'pendingFlickrClaims Query', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  def build_query
    <<~GQL
      query {
        pendingFlickrClaims {
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

  context 'when the user is not an admin' do
    let(:user) { create(:user) }
    let(:query) { build_query }

    before { sign_in(user) }

    it 'returns an empty list without errors' do
      post_query
      expect(data_dig(response, 'pendingFlickrClaims')).to be_empty
      expect(first_error_message(response)).to be_nil
    end
  end

  context 'when the user is an admin' do
    let(:admin) { create(:user, admin: true) }
    let!(:claim1) { create(:flickr_user_claim, :automatic, status: 'pending') }
    let!(:claim2) { create(:flickr_user_claim, :manual, status: 'pending') }
    let(:query) { build_query }

    before { sign_in(admin) }

    it 'returns the pending claims' do
      post_query
      items = data_dig(response, 'pendingFlickrClaims')

      expect(items.size).to eq(2)

      item1 = items.detect { |i| i['id'] == claim1.id.to_s }
      item2 = items.detect { |i| i['id'] == claim2.id.to_s }

      expect(item1).to include(
        'id' => claim1.id.to_s,
        'status' => 'pending',
        'claimType' => 'automatic'
      )
      expect(item1['verificationCode']).to be_present
      expect(item1.dig('user', 'id')).to eq(claim1.user.slug)
      expect(item1.dig('flickrUser', 'nsid')).to eq(claim1.flickr_user.nsid)

      expect(item2).to include(
        'id' => claim2.id.to_s,
        'status' => 'pending',
        'claimType' => 'manual'
      )
      expect(item2.dig('user', 'id')).to eq(claim2.user.slug)
      expect(item2.dig('flickrUser', 'nsid')).to eq(claim2.flickr_user.nsid)
    end
  end
end
