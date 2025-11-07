# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'denyFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) do
    post '/graphql',
         params: {
           query: query,
           variables: variables
         }
  end

  let(:user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:flickr_user) { create(:flickr_user) }
  let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user, status: 'pending') }

  let(:variables) do
    {
      claimId: claim.id
    }
  end

  let(:query) do
    <<~GQL
      mutation DenyFlickrClaim($claimId: ID!) {
        denyFlickrClaim(claimId: $claimId) {
          claim {
            id
            status
            deniedAt
            flickrUser {
              id
              claimedByUser {
                id
              }
            }
          }
          success
          errors
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns an error' do
      post_mutation

      json = response.parsed_body
      result = json['data']['denyFlickrClaim']

      expect(result['claim']).to be_nil
      expect(result['success']).to be false
      expect(result['errors']).to include('You must be signed in')
    end
  end

  context 'when a regular user is logged in' do
    before { sign_in(user) }

    it 'returns an authorization error' do
      post_mutation

      json = response.parsed_body
      result = json['data']['denyFlickrClaim']

      expect(result['claim']).to be_nil
      expect(result['success']).to be false
      expect(result['errors']).to include('Not authorized to deny claims')
    end
  end

  context 'when an admin is logged in' do
    before { sign_in(admin_user) }

    context 'when the claim is not found' do
      let(:variables) do
        {
          claimId: 999999
        }
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['denyFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['success']).to be false
        expect(result['errors']).to include('Claim not found')
      end
    end

    context 'when the claim is not pending' do
      let(:claim) { create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user) }

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['denyFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['success']).to be false
        expect(result['errors']).to include('Claim is not pending')
      end
    end

    context 'when the claim is valid' do
      it 'denies the claim and does not associate the Flickr user' do
        post_mutation

        json = response.parsed_body
        result = json['data']['denyFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['status']).to eq('denied')
        expect(result['claim']['deniedAt']).to be_present
        expect(result['claim']['flickrUser']['claimedByUser']).to be_nil
        expect(result['success']).to be true
        expect(result['errors']).to eq([])

        claim.reload
        expect(claim.status).to eq('denied')
        expect(claim.denied_at).to be_present

        flickr_user.reload
        expect(flickr_user.claimed_by_user_id).to be_nil
      end

      it 'enqueues an email to the user' do
        expect do
          post_mutation
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'flickr_claim_denied', 'deliver_now', { args: [{ user: user, flickr_user: flickr_user }] })
      end
    end

    context 'when denying an automatic claim' do
      let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }

      it 'successfully denies the claim' do
        post_mutation

        json = response.parsed_body
        result = json['data']['denyFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['status']).to eq('denied')
        expect(result['success']).to be true
        expect(result['errors']).to eq([])
      end
    end

    context 'when denying a manual claim' do
      let(:claim) { create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user, reason: 'Lost access') }

      it 'successfully denies the claim' do
        post_mutation

        json = response.parsed_body
        result = json['data']['denyFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['status']).to eq('denied')
        expect(result['success']).to be true
        expect(result['errors']).to eq([])
      end
    end

    context 'when denying a claim does not affect other users claims' do
      let(:another_user) { create(:user) }
      let(:another_claim) { create(:flickr_user_claim, user: another_user, flickr_user: create(:flickr_user)) }

      it 'only denies the specified claim' do
        post_mutation

        claim.reload
        expect(claim.status).to eq('denied')

        another_claim.reload
        expect(another_claim.status).to eq('pending')
      end
    end
  end
end
