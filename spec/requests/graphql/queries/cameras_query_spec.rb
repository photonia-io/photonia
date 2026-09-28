# frozen_string_literal: true

require 'rails_helper'

describe 'cameras Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  include_context 'with auth actors'

  let(:query) do
    <<~GQL
      query {
        cameras {
          make
          model
          friendlyName
          count
        }
      }
    GQL
  end

  it 'groups photos by camera make and model, with counts, most used first' do
    create_list(:photo, 2, exif: { 'ifd0' => { 'make' => 'Canon', 'model' => 'EOS R5' } })
    create(:photo, exif: { 'ifd0' => { 'make' => 'Nikon', 'model' => 'Z6' } })
    create(:photo, exif: nil)

    post_query

    cameras = response.parsed_body.dig('data', 'cameras')
    expect(cameras).to eq(
      [
        { 'make' => 'Canon', 'model' => 'EOS R5', 'friendlyName' => 'Canon EOS R5', 'count' => 2 },
        { 'make' => 'Nikon', 'model' => 'Z6', 'friendlyName' => 'Nikon Z6', 'count' => 1 }
      ]
    )
  end

  it "hides a private photo's camera from a visitor" do
    create(:photo, privacy: 'private', exif: { 'ifd0' => { 'make' => 'Canon', 'model' => 'EOS R5' } })

    post_query

    expect(response.parsed_body.dig('data', 'cameras')).to be_empty
  end
end
