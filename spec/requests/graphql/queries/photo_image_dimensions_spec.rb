# frozen_string_literal: true

require 'rails_helper'

# Covers PhotoType#image_dimensions, which must read the *displayed
# derivative's* stored metadata - never the original's, which can disagree
# when the original carries an EXIF rotation flag (derivatives are
# auto-oriented when generated; the original's stored metadata is not).
RSpec.describe 'photo imageDimensions', type: :request do
  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:query) do
    <<~GQL
      query {
        photo(id: "#{photo.slug}") {
          thumbnail: imageDimensions(type: "thumbnail") { width height }
          medium: imageDimensions(type: "medium") { width height }
          extralarge: imageDimensions(type: "extralarge") { width height }
        }
      }
    GQL
  end

  def file_with_dimensions(dimensions)
    file = TestData.uploaded_image
    file.metadata.merge!('width' => dimensions[:width], 'height' => dimensions[:height])
    file
  end

  def image_with_dimensions(original:, derivatives:)
    attacher = Shrine::Attacher.new
    attacher.set(file_with_dimensions(original))
    attacher.set_derivatives(derivatives.transform_values { |dimensions| file_with_dimensions(dimensions) })
    attacher.data
  end

  context 'when the original is landscape and stored with an EXIF rotation flag' do
    # Regression: photo 3400469719 in production - original stored 3872x2592
    # (landscape) but the extralarge derivative, which is what actually
    # renders, is auto-oriented to 1371x2048 (portrait).
    let(:photo) do
      create(:photo, image_data: image_with_dimensions(
        original: { width: 3872, height: 2592 },
        derivatives: {
          thumbnail_square: { width: 150, height: 150 },
          medium_square: { width: 1371, height: 2048 },
          extralarge: { width: 1371, height: 2048 }
        }
      ))
    end

    it "returns the derivative's own portrait dimensions, not the original's landscape ones" do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['extralarge']).to eq('width' => 1371, 'height' => 2048)
      expect(data['medium']).to eq('width' => 1371, 'height' => 2048)
    end
  end

  context 'when the derivative has no stored metadata' do
    let(:photo) { create(:photo, image_data: TestData.image_data) }

    it 'returns null rather than falling back to the original dimensions' do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['thumbnail']).to be_nil
    end
  end

  context 'when a user-defined derivative also exists' do
    let(:photo) do
      create(:photo, image_data: image_with_dimensions(
        original: { width: 2000, height: 1000 },
        derivatives: {
          thumbnail_square: { width: 150, height: 150 },
          thumbnail_intelligent: { width: 150, height: 150 },
          thumbnail_user: { width: 300, height: 300 }
        }
      ))
    end

    it 'follows the same user > intelligent > square priority as imageUrl' do
      post_query
      data = response.parsed_body['data']['photo']

      expect(data['thumbnail']).to eq('width' => 300, 'height' => 300)
    end
  end
end
