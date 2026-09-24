# frozen_string_literal: true

require 'rails_helper'

# Covers PhotoType#image_url's user-defined > intelligent > square priority
# chain for the "thumbnail" and "medium" GraphQL types.
RSpec.describe 'photo imageUrl priority', type: :request do
  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:query) do
    <<~GQL
      query {
        photo(id: "#{photo.slug}") {
          thumbnail: imageUrl(type: "thumbnail")
          medium: imageUrl(type: "medium")
        }
      }
    GQL
  end

  def image_data_with(derivatives)
    attacher = Shrine::Attacher.new
    attacher.set(TestData.uploaded_image)
    attacher.set_derivatives(derivatives)
    attacher.data
  end

  context 'when only the square derivative exists' do
    let(:photo) do
      create(:photo, image_data: image_data_with(
        thumbnail_square: TestData.uploaded_image,
        medium_square: TestData.uploaded_image
      ))
    end

    it 'falls back to the square derivative' do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['thumbnail']).to eq photo.image_url(:thumbnail_square)
      expect(data['medium']).to eq photo.image_url(:medium_square)
    end
  end

  context 'when an intelligent derivative also exists' do
    let(:photo) do
      create(:photo, image_data: image_data_with(
        thumbnail_square: TestData.uploaded_image,
        thumbnail_intelligent: TestData.uploaded_image,
        medium_square: TestData.uploaded_image,
        medium_intelligent: TestData.uploaded_image
      ))
    end

    it 'prefers the intelligent derivative over the square one' do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['thumbnail']).to eq photo.image_url(:thumbnail_intelligent)
      expect(data['medium']).to eq photo.image_url(:medium_intelligent)
    end
  end

  context 'when a user-defined derivative also exists' do
    let(:photo) do
      create(:photo, image_data: image_data_with(
        thumbnail_square: TestData.uploaded_image,
        thumbnail_intelligent: TestData.uploaded_image,
        thumbnail_user: TestData.uploaded_image,
        medium_square: TestData.uploaded_image,
        medium_intelligent: TestData.uploaded_image,
        medium_user: TestData.uploaded_image
      ))
    end

    it 'prefers the user-defined derivative over intelligent and square' do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['thumbnail']).to eq photo.image_url(:thumbnail_user)
      expect(data['medium']).to eq photo.image_url(:medium_user)
    end
  end
end
