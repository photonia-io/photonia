# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'resetPhotoTakenAt Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:photo) { create(:photo, user: owner, image_data: TestData.image_data) }

  let(:query) do
    <<~GQL
      mutation {
        resetPhotoTakenAt(id: "#{photo.slug}") {
          id
          taken_at_info: takenAtInfo {
            precision
            source
          }
        }
      }
    GQL
  end

  before do
    photo.assign_taken_at(year: 1990, scanned: photo.scanned)
    photo.save!
  end

  context 'when the photo is not found' do
    before { photo.destroy }

    it 'returns an error' do
      post_mutation

      expect(first_error_message(response)).to eq('Photo not found')
    end
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls resetPhotoTakenAt' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['resetPhotoTakenAt'])
      expect(data_dig(response, 'resetPhotoTakenAt')).to be_nil
    end
  end

  context 'when a different user is logged in' do
    before { sign_in(stranger) }

    it 'returns NOT_FOUND error' do
      post_mutation

      expect(data_dig(response, 'resetPhotoTakenAt')).to be_nil
    end
  end

  context 'when the owner is logged in' do
    before { sign_in(owner) }

    it 're-derives taken_at from EXIF' do
      post_mutation
      data = data_dig(response, 'resetPhotoTakenAt')

      expect(data['taken_at_info']).to include('precision' => 'minute', 'source' => 'exif')
      expect(photo.reload.taken_at_source).to eq('exif')
    end

    context 'when the photo has no EXIF data' do
      let(:photo) { create(:photo, user: owner, image: File.open('spec/support/images/zell-am-see-without-exif.jpg')) }

      it 'falls back to posted_at, source unknown' do
        post_mutation
        data = data_dig(response, 'resetPhotoTakenAt')

        expect(data['taken_at_info']).to include('source' => 'unknown')
        expect(photo.reload.taken_at).to eq(photo.posted_at)
      end
    end

    context 'when the photo is scanned' do
      let(:photo) { create(:photo, :scanned, user: owner, image_data: TestData.image_data) }

      it 'ignores the EXIF date, falls back to posted_at, and stays scanned' do
        post_mutation
        data = data_dig(response, 'resetPhotoTakenAt')

        expect(data['taken_at_info']).to include('source' => 'unknown')
        expect(photo.reload.scanned).to be true
        expect(photo.taken_at).to eq(photo.posted_at)
      end
    end
  end

  context 'when an admin is logged in' do
    before { sign_in(admin) }

    it "allows resetting another user's photo date" do
      post_mutation

      expect(photo.reload.taken_at_source).to eq('exif')
    end
  end
end
