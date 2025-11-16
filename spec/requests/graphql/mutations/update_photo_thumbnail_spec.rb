# frozen_string_literal: true

require 'rails_helper'

describe 'updatePhotoThumbnail Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo) }
  let(:thumbnail_data) do
    {
      top: 0.25,
      left: 0.25,
      width: 0.5,
      height: 0.5
    }
  end

  let(:query) do
    <<~GQL
      mutation {
        updatePhotoThumbnail(
          id: "#{photo.id}"
          thumbnail: {
            top: #{thumbnail_data[:top]}
            left: #{thumbnail_data[:left]}
            width: #{thumbnail_data[:width]}
            height: #{thumbnail_data[:height]}
          }
        ) {
          id
          userThumbnail {
            top
            left
            width
            height
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls updatePhotoThumbnail' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['updatePhotoThumbnail'])
      expect(json.dig('data', 'updatePhotoThumbnail')).to be_nil
    end
  end

  context 'when the user is logged in' do
    let(:photo) { create(:photo, :with_image) }

    before do
      sign_in(photo.user)
    end

    it 'updates the photo user thumbnail' do
      post_mutation
      json = response.parsed_body
      data = json['data']['updatePhotoThumbnail']

      expect(data['id']).to eq(photo.slug)
      expect(data['userThumbnail']['top']).to eq(thumbnail_data[:top])
      expect(data['userThumbnail']['left']).to eq(thumbnail_data[:left])
      expect(data['userThumbnail']['width']).to eq(thumbnail_data[:width])
      expect(data['userThumbnail']['height']).to eq(thumbnail_data[:height])
    end

    it 'stores the thumbnail in the database' do
      expect { post_mutation }.to change { photo.reload.user_thumbnail }.from(nil)

      expect(photo.user_thumbnail['top']).to eq(thumbnail_data[:top])
      expect(photo.user_thumbnail['left']).to eq(thumbnail_data[:left])
      expect(photo.user_thumbnail['width']).to eq(thumbnail_data[:width])
      expect(photo.user_thumbnail['height']).to eq(thumbnail_data[:height])
    end

    it 'enqueues a job to regenerate derivatives' do
      ActiveJob::Base.queue_adapter = :test

      expect do
        post_mutation
      end.to have_enqueued_job(AddDerivativesJob).with(photo.id)
    end

    context 'with invalid thumbnail values' do
      context 'when top is out of range' do
        let(:thumbnail_data) { { top: 1.5, left: 0.25, width: 0.5, height: 0.5 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Top must be between 0.0 and 1.0')
        end
      end

      context 'when left is negative' do
        let(:thumbnail_data) { { top: 0.25, left: -0.1, width: 0.5, height: 0.5 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Left must be between 0.0 and 1.0')
        end
      end

      context 'when width exceeds 1.0' do
        let(:thumbnail_data) { { top: 0.25, left: 0.25, width: 1.2, height: 0.5 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Width must be between 0.0 and 1.0')
        end
      end

      context 'when height is negative' do
        let(:thumbnail_data) { { top: 0.25, left: 0.25, width: 0.5, height: -0.1 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Height must be between 0.0 and 1.0')
        end
      end

      context 'when top + height exceeds 1.0' do
        let(:thumbnail_data) { { top: 0.6, left: 0.25, width: 0.5, height: 0.5 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Top + height must not exceed 1.0')
        end
      end

      context 'when left + width exceeds 1.0' do
        let(:thumbnail_data) { { top: 0.25, left: 0.7, width: 0.5, height: 0.5 } }

        it 'returns an error' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Left + width must not exceed 1.0')
        end
      end

      context 'with multiple validation errors' do
        let(:thumbnail_data) { { top: 1.5, left: -0.1, width: 0.5, height: 0.5 } }

        it 'returns all errors' do
          post_mutation
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('Top must be between 0.0 and 1.0')
          expect(err['message']).to include('Left must be between 0.0 and 1.0')
        end
      end
    end

    context 'with valid edge case values' do
      context 'when values are at minimum (0.0)' do
        let(:thumbnail_data) { { top: 0.0, left: 0.0, width: 1.0, height: 1.0 } }

        it 'successfully updates the thumbnail' do
          post_mutation
          json = response.parsed_body
          data = json['data']['updatePhotoThumbnail']

          expect(data).to be_present
          expect(data['userThumbnail']['top']).to eq(0.0)
          expect(data['userThumbnail']['left']).to eq(0.0)
        end
      end

      context 'when values are at maximum (1.0)' do
        let(:thumbnail_data) { { top: 0.0, left: 0.0, width: 1.0, height: 1.0 } }

        it 'successfully updates the thumbnail' do
          post_mutation
          json = response.parsed_body
          data = json['data']['updatePhotoThumbnail']

          expect(data).to be_present
          expect(data['userThumbnail']['width']).to eq(1.0)
          expect(data['userThumbnail']['height']).to eq(1.0)
        end
      end

      context 'when boundaries are exactly at limit' do
        let(:thumbnail_data) { { top: 0.5, left: 0.5, width: 0.5, height: 0.5 } }

        it 'successfully updates the thumbnail' do
          post_mutation
          json = response.parsed_body
          data = json['data']['updatePhotoThumbnail']

          expect(data).to be_present
          expect(data['userThumbnail']['top']).to eq(0.5)
          expect(data['userThumbnail']['left']).to eq(0.5)
        end
      end
    end
  end
end
