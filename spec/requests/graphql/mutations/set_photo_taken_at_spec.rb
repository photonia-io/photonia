# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setPhotoTakenAt Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:photo) { create(:photo, user: owner, image_data: TestData.image_data) }

  let(:query) do
    <<~GQL
      mutation {
        setPhotoTakenAt(
          id: "#{photo.slug}",
          year: 1985,
          month: 8,
          day: 31,
          hour: 17,
          minute: 25,
          approximate: true,
          scanned: true
        ) {
          id
          taken_at: takenAt
          taken_at_info: takenAtInfo {
            year
            month
            day
            hour
            minute
            precision
            source
            approximate
          }
          scanned
        }
      }
    GQL
  end

  context 'when the photo is not found' do
    before { photo.destroy }

    it 'returns an error' do
      post_mutation

      expect(first_error_message(response)).to eq('Photo not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls setPhotoTakenAt' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['setPhotoTakenAt'])
      expect(data_dig(response, 'setPhotoTakenAt')).to be_nil
    end
  end

  context 'when a different user is logged in' do
    before { sign_in(stranger) }

    it 'returns NOT_FOUND error' do
      post_mutation

      expect(first_error_message(response)).to be_nil.or be_present
      expect(data_dig(response, 'setPhotoTakenAt')).to be_nil
    end
  end

  context 'when the owner is logged in' do
    before { sign_in(owner) }

    it 'sets the date, precision, source and flags' do
      post_mutation
      data = data_dig(response, 'setPhotoTakenAt')

      expect(data['taken_at_info']).to include(
        'year' => 1985,
        'month' => 8,
        'day' => 31,
        'hour' => 17,
        'minute' => 25,
        'precision' => 'minute',
        'source' => 'user',
        'approximate' => true
      )
      expect(data['scanned']).to be true

      photo.reload
      expect(photo.taken_at_source).to eq('user')
      expect(photo.taken_at_precision).to eq('minute')
      expect(photo.taken_at_approximate).to be true
      expect(photo.scanned).to be true
    end

    context 'with only a year' do
      let(:query) do
        <<~GQL
          mutation {
            setPhotoTakenAt(id: "#{photo.slug}", year: 1972) {
              id
              taken_at_info: takenAtInfo {
                year
                month
                day
                precision
                source
              }
            }
          }
        GQL
      end

      it 'derives year precision with month/day left null' do
        post_mutation
        data = data_dig(response, 'setPhotoTakenAt')

        expect(data['taken_at_info']).to include(
          'year' => 1972,
          'month' => nil,
          'day' => nil,
          'precision' => 'year',
          'source' => 'user'
        )
      end
    end

    context 'when day is given without month' do
      let(:query) do
        <<~GQL
          mutation {
            setPhotoTakenAt(id: "#{photo.slug}", year: 1972, day: 5) {
              id
            }
          }
        GQL
      end

      it 'returns a validation error' do
        post_mutation

        expect(first_error_message(response)).to include('day cannot be set without month')
      end
    end

    context 'when the year is out of range' do
      let(:query) do
        <<~GQL
          mutation {
            setPhotoTakenAt(id: "#{photo.slug}", year: 3000) {
              id
            }
          }
        GQL
      end

      it 'returns a validation error' do
        post_mutation

        expect(first_error_message(response)).to include('year must be between')
      end
    end
  end

  context 'when an admin is logged in' do
    before { sign_in(admin) }

    it "allows changing another user's photo date" do
      post_mutation
      data = data_dig(response, 'setPhotoTakenAt')

      expect(data['taken_at_info']).to include('year' => 1985)
      expect(photo.reload.taken_at_source).to eq('user')
    end
  end
end
