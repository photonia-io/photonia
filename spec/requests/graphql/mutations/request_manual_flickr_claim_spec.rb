# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requestManualFlickrClaim Mutation', type: :request do
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
  let(:reason) { 'I lost access to my Flickr account' }

  let(:variables) do
    {
      flickrUserNsid: flickr_user.nsid,
      reason: reason
    }
  end

  let(:query) do
    <<~GQL
      mutation RequestManualFlickrClaim($flickrUserNsid: String!, $reason: String) {
        requestManualFlickrClaim(flickrUserNsid: $flickrUserNsid, reason: $reason) {
          claim {
            id
            claimType
            status
            reason
            verificationCode
            flickrUser {
              id
              username
            }
            user {
              id
              displayName
            }
          }
          errors
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns an error' do
      post_mutation

      json = response.parsed_body
      result = json['data']['requestManualFlickrClaim']

      expect(result['claim']).to be_nil
      expect(result['errors']).to include('You must be signed in')
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
      create(:user, admin: true, email: 'admin@example.com')
    end

    context 'when the Flickr user is not found' do
      let(:variables) do
        {
          flickrUserNsid: 'nonexistent-nsid',
          reason: reason
        }
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['errors']).to include('Flickr user not found')
      end
    end

    context 'when the Flickr user has already been claimed' do
      let(:other_user) { create(:user) }

      before do
        flickr_user.update!(claimed_by_user: other_user)
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['errors']).to include('This Flickr user has already been claimed')
      end
    end

    context 'when the user already has a pending claim for this Flickr user' do
      let!(:existing_claim) do
        create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user, status: 'pending')
      end

      it 'returns the existing claim without creating a new one' do
        expect do
          post_mutation
        end.not_to change(FlickrUserClaim, :count)

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['id']).to eq(existing_claim.id.to_s)
        expect(result['errors']).to eq([])
      end
    end

    context 'when the request is valid' do
      it 'creates a new manual claim with reason' do
        expect do
          post_mutation
        end.to change(FlickrUserClaim, :count).by(1)

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['claimType']).to eq('manual')
        expect(result['claim']['status']).to eq('pending')
        expect(result['claim']['reason']).to eq(reason)
        expect(result['claim']['verificationCode']).to be_nil
        expect(result['claim']['user']['id']).to eq(user.slug)
        expect(result['claim']['flickrUser']['id']).to eq(flickr_user.serial_number.to_s)
        expect(result['errors']).to eq([])
      end

      it 'enqueues an email to admins' do
        expect do
          post_mutation
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('AdminMailer', 'flickr_claim_request', 'deliver_now', hash_including(args: [hash_including(:user, :flickr_user, :claim, :reason)]))
      end
    end

    context 'when the reason is not provided' do
      let(:variables) do
        {
          flickrUserNsid: flickr_user.nsid
        }
      end

      it 'creates a claim without reason' do
        expect do
          post_mutation
        end.to change(FlickrUserClaim, :count).by(1)

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['claimType']).to eq('manual')
        expect(result['claim']['reason']).to be_nil
        expect(result['errors']).to eq([])
      end
    end

    context 'when the user has a denied claim for this Flickr user' do
      let!(:denied_claim) do
        create(:flickr_user_claim, :manual, :denied, user: user, flickr_user: flickr_user)
      end

      it 'creates a new claim' do
        expect do
          post_mutation
        end.to change(FlickrUserClaim, :count).by(1)

        json = response.parsed_body
        result = json['data']['requestManualFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['id']).not_to eq(denied_claim.id.to_s)
        expect(result['claim']['status']).to eq('pending')
        expect(result['errors']).to eq([])
      end
    end
  end
end
