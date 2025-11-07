# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'verifyAutomaticFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) do
    post '/graphql',
         params: {
           query: query,
           variables: variables
         }
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }
  let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }

  let(:variables) do
    {
      claimId: claim.id
    }
  end

  let(:query) do
    <<~GQL
      mutation VerifyAutomaticFlickrClaim($claimId: ID!) {
        verifyAutomaticFlickrClaim(claimId: $claimId) {
          claim {
            id
            status
            verifiedAt
            approvedAt
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
      result = json['data']['verifyAutomaticFlickrClaim']

      expect(result['claim']).to be_nil
      expect(result['success']).to be false
      expect(result['errors']).to include('You must be signed in')
    end
  end

  context 'when the user is logged in' do
    before { sign_in(user) }

    context 'when the claim is not found' do
      let(:variables) do
        {
          claimId: 999999
        }
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['success']).to be false
        expect(result['errors']).to include('Claim not found')
      end
    end

    context 'when the claim belongs to another user' do
      before { sign_in(other_user) }

      it 'returns an authorization error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['success']).to be false
        expect(result['errors']).to include('Not authorized to verify this claim')
      end
    end

    context 'when the claim is not pending' do
      let(:claim) { create(:flickr_user_claim, :automatic, :approved, user: user, flickr_user: flickr_user) }

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['success']).to be false
        expect(result['errors']).to include('Claim is not pending')
      end
    end

    context 'when the verification code is found in the Flickr profile' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return("My profile description with verification code: #{claim.verification_code}")
      end

      it 'verifies and approves the claim' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['status']).to eq('approved')
        expect(result['claim']['verifiedAt']).to be_present
        expect(result['claim']['approvedAt']).to be_present
        expect(result['success']).to be true
        expect(result['errors']).to eq([])

        claim.reload
        expect(claim.status).to eq('approved')
        expect(claim.verified_at).to be_present
        expect(claim.approved_at).to be_present

        flickr_user.reload
        expect(flickr_user.claimed_by_user_id).to eq(user.id)
      end

      it 'enqueues an email to the user' do
        expect do
          post_mutation
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'flickr_claim_approved', 'deliver_now', { args: [{ user: user, flickr_user: flickr_user }] })
      end
    end

    context 'when the verification code is not found in the Flickr profile' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return('My profile description without the code')
      end

      it 'returns an error and does not approve the claim' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['status']).to eq('pending')
        expect(result['success']).to be false
        expect(result['errors']).to include('Verification code not found in Flickr profile description')

        claim.reload
        expect(claim.status).to eq('pending')
        expect(claim.verified_at).to be_nil
        expect(claim.approved_at).to be_nil

        flickr_user.reload
        expect(flickr_user.claimed_by_user_id).to be_nil
      end
    end

    context 'when unable to fetch the Flickr profile' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return(nil)
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['success']).to be false
        expect(result['errors']).to include('Unable to fetch Flickr profile')

        claim.reload
        expect(claim.status).to eq('pending')
      end
    end

    context 'when the claim type is manual' do
      let(:claim) { create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user) }

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['verifyAutomaticFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['success']).to be false
        expect(result['errors']).to include('Invalid claim type')
      end
    end
  end
end
