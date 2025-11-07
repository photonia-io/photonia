# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'myFlickrClaims Query', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  def build_query
    <<~GQL
      query {
        myFlickrClaims {
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
    let(:query) { build_query }

    it 'returns an empty list' do
      post_query
      expect(data_dig(response, 'myFlickrClaims')).to be_empty
    end
  end

  context 'when the user is logged in' do
    let(:user) { create(:user) }
    let!(:claim1) { create(:flickr_user_claim, :automatic, user: user) }
    let!(:claim2) { create(:flickr_user_claim, :manual, user: user) }
    let(:query) { build_query }

    before { sign_in(user) }

    it 'returns the user\'s claims' do
      post_query
      items = data_dig(response, 'myFlickrClaims')

      expect(items.size).to eq(2)

      item1 = items.detect { |i| i['id'] == claim1.id.to_s }
      item2 = items.detect { |i| i['id'] == claim2.id.to_s }

      expect(item1).to include(
        'id' => claim1.id.to_s,
        'status' => claim1.status,
        'claimType' => claim1.claim_type
      )
      expect(item1['verificationCode']).to be_present if claim1.claim_type == 'automatic'
      expect(item1.dig('user', 'id')).to eq(user.slug)
      expect(item1.dig('flickrUser', 'nsid')).to eq(claim1.flickr_user.nsid)

      expect(item2).to include(
        'id' => claim2.id.to_s,
        'status' => claim2.status,
        'claimType' => claim2.claim_type
      )
      expect(item2.dig('user', 'id')).to eq(user.slug)
      expect(item2.dig('flickrUser', 'nsid')).to eq(claim2.flickr_user.nsid)
    end
  end
end
