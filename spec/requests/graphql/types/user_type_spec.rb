# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UserType pendingFlickrClaims field', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:target_user) { create(:user) }
  let!(:pending_claim) { create(:flickr_user_claim, user: target_user, status: 'pending') }
  # a user can only have one active (pending/approved) claim at a time, so use a denied
  # one alongside the pending claim to prove pendingFlickrClaims filters by status
  let!(:denied_claim) { create(:flickr_user_claim, :denied, user: target_user) }

  context 'when an admin queries another user\'s pending claims' do
    let(:admin) { create(:user, admin: true) }
    let(:query) do
      <<~GQL
        query {
          user(id: "#{target_user.slug}") {
            pendingFlickrClaims {
              id
              status
              flickrUser { nsid }
            }
          }
        }
      GQL
    end

    before { sign_in(admin) }

    it 'returns only the pending claims, not approved/denied ones' do
      post_query
      claims = data_dig(response, 'user', 'pendingFlickrClaims')

      expect(claims.size).to eq(1)
      expect(claims.first).to include('id' => pending_claim.id.to_s, 'status' => 'pending')
    end
  end

  context 'when a non-admin queries their own pendingFlickrClaims via currentUser' do
    let(:query) do
      <<~GQL
        query {
          currentUser {
            pendingFlickrClaims {
              id
            }
          }
        }
      GQL
    end

    before { sign_in(target_user) }

    it 'returns an empty list, even though the user has a pending claim of their own' do
      post_query
      claims = data_dig(response, 'currentUser', 'pendingFlickrClaims')

      expect(claims).to eq([])
    end
  end
end
