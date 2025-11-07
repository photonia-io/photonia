# frozen_string_literal: true

require 'rails_helper'

describe 'flickrUserClaim Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:other_user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }
  let!(:flickr_user_claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

  let(:query) do
    <<~GQL
      query {
        flickrUserClaim(id: #{flickr_user_claim.id}) {
          id
          claimType
          status
          verificationCode
          reason
          verifiedAt
          approvedAt
          deniedAt
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
    it 'returns null' do
      post_query

      json = response.parsed_body

      expect(json['data']['flickrUserClaim']).to be_nil
    end
  end

  context 'when the user is logged in' do
    context 'and the claim belongs to the user' do
      before do
        sign_in(user)
      end

      it 'returns the flickr user claim' do
        post_query

        json = response.parsed_body
        claim_data = json['data']['flickrUserClaim']

        expect(claim_data).to be_present
        expect(claim_data['id']).to eq(flickr_user_claim.id.to_s)
        expect(claim_data['claimType']).to eq(flickr_user_claim.claim_type)
        expect(claim_data['status']).to eq(flickr_user_claim.status)
        expect(claim_data['user']['id']).to eq(user.slug)
        expect(claim_data['flickrUser']['id']).to eq(flickr_user.serial_number.to_s)
      end
    end

    context 'and the claim belongs to another user' do
      before do
        sign_in(other_user)
      end

      it 'returns null due to authorization failure' do
        post_query

        json = response.parsed_body

        expect(json['data']['flickrUserClaim']).to be_nil
      end
    end

    context 'and the user is an admin' do
      before do
        sign_in(admin_user)
      end

      it 'returns the flickr user claim' do
        post_query

        json = response.parsed_body
        claim_data = json['data']['flickrUserClaim']

        expect(claim_data).to be_present
        expect(claim_data['id']).to eq(flickr_user_claim.id.to_s)
        expect(claim_data['status']).to eq(flickr_user_claim.status)
      end
    end
  end

  context 'when the claim ID does not exist' do
    let(:query) do
      <<~GQL
        query {
          flickrUserClaim(id: 999999) {
            id
          }
        }
      GQL
    end

    before do
      sign_in(user)
    end

    it 'returns null' do
      post_query

      json = response.parsed_body

      expect(json['data']['flickrUserClaim']).to be_nil
    end
  end
end
