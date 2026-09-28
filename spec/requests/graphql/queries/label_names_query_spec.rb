# frozen_string_literal: true

require 'rails_helper'

describe 'labelNames Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  let(:query) do
    <<~GQL
      query {
        labelNames(query: "do") {
          name
          count
        }
      }
    GQL
  end

  it 'groups labels by name, prefix-filtered, with counts, most used first' do
    dog_photos = create_list(:photo, 2)
    dog_photos.each { |photo| create(:label, photo:, name: 'Dog') }
    door_photo = create(:photo)
    create(:label, photo: door_photo, name: 'Door')
    cat_photo = create(:photo)
    create(:label, photo: cat_photo, name: 'Cat')

    post_query

    expect(response.parsed_body.dig('data', 'labelNames')).to eq(
      [
        { 'name' => 'Dog', 'count' => 2 },
        { 'name' => 'Door', 'count' => 1 }
      ]
    )
  end

  it "hides a private photo's label from a visitor" do
    private_photo = create(:photo, privacy: 'private')
    create(:label, photo: private_photo, name: 'Dog')

    post_query

    expect(response.parsed_body.dig('data', 'labelNames')).to be_empty
  end
end
