# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requestAutomaticFlickrClaim Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) do
    post '/graphql',
         params: {
           query: query,
           variables: variables
         }
  end

  let(:user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }

  let(:variables) do
    {
      flickrUserNsid: flickr_user.nsid
    }
  end

  let(:query) do
    <<~GQL
      mutation RequestAutomaticFlickrClaim($flickrUserNsid: String!) {
        requestAutomaticFlickrClaim(flickrUserNsid: $flickrUserNsid) {
          claim {
            id
            claimType
            status
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
      result = json['data']['requestAutomaticFlickrClaim']

      expect(result['claim']).to be_nil
      expect(result['errors']).to include('You must be signed in')
    end
  end

  context 'when the user is logged in' do
    before { sign_in(user) }

    context 'when the Flickr user is not found' do
      let(:variables) do
        {
          flickrUserNsid: 'nonexistent-nsid'
        }
      end

      it 'returns an error' do
        post_mutation

        json = response.parsed_body
        result = json['data']['requestAutomaticFlickrClaim']

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
        result = json['data']['requestAutomaticFlickrClaim']

        expect(result['claim']).to be_nil
        expect(result['errors']).to include('This Flickr user has already been claimed')
      end
    end

    context 'when the user already has a pending claim for this Flickr user' do
      let!(:existing_claim) do
        create(:flickr_user_claim, user: user, flickr_user: flickr_user, status: 'pending')
      end

      it 'returns the existing claim without creating a new one' do
        expect do
          post_mutation
        end.not_to change(FlickrUserClaim, :count)

        json = response.parsed_body
        result = json['data']['requestAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['id']).to eq(existing_claim.id.to_s)
        expect(result['errors']).to eq([])
      end
    end

    context 'when the request is valid' do
      it 'creates a new automatic claim with verification code' do
        expect do
          post_mutation
        end.to change(FlickrUserClaim, :count).by(1)

        json = response.parsed_body
        result = json['data']['requestAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['claimType']).to eq('automatic')
        expect(result['claim']['status']).to eq('pending')
        expect(result['claim']['verificationCode']).to be_present
        expect(result['claim']['verificationCode'].length).to eq(10)
        expect(result['claim']['user']['id']).to eq(user.slug)
        expect(result['claim']['flickrUser']['id']).to eq(flickr_user.serial_number.to_s)
        expect(result['errors']).to eq([])
      end

      it 'generates a unique verification code' do
        post_mutation

        json = response.parsed_body
        result = json['data']['requestAutomaticFlickrClaim']

        verification_code = result['claim']['verificationCode']
        expect(verification_code).to match(/^[a-zA-Z0-9]{10}$/)
      end
    end

    context 'when the user has a denied claim for this Flickr user' do
      let!(:denied_claim) do
        create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user)
      end

      it 'creates a new claim' do
        expect do
          post_mutation
        end.to change(FlickrUserClaim, :count).by(1)

        json = response.parsed_body
        result = json['data']['requestAutomaticFlickrClaim']

        expect(result['claim']).to be_present
        expect(result['claim']['id']).not_to eq(denied_claim.id.to_s)
        expect(result['claim']['status']).to eq('pending')
        expect(result['errors']).to eq([])
      end
    end
  end
end
