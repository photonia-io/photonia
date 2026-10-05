# frozen_string_literal: true

require 'rails_helper'

describe 'album Query - sort date shortcuts' do
  include Devise::Test::IntegrationHelpers
  include_context 'with auth actors'

  subject(:album_json) do
    post '/graphql', params: { query: }
    response.parsed_body.dig('data', 'album')
  end

  let(:album) { create(:album, user: owner, sort_date: Date.new(2020, 1, 2)) }

  let(:query) do
    <<~GQL
      query {
        album(id: "#{album.slug}") {
          sortDate
          firstPhotoTakenAt
          lastPhotoTakenAt
        }
      }
    GQL
  end

  before do
    album.photos << create(:photo, taken_at: Time.zone.local(2015, 3, 1, 10))
    album.photos << create(:photo, taken_at: Time.zone.local(2018, 7, 9, 18))
    album.maintenance
  end

  it 'exposes the sort date publicly but hides photo dates from visitors' do
    expect(album_json).to eq('sortDate' => '2020-01-02', 'firstPhotoTakenAt' => nil, 'lastPhotoTakenAt' => nil)
  end

  it 'gives the owner the first and latest photo dates' do
    sign_in(owner)

    expect(album_json).to eq('sortDate' => '2020-01-02', 'firstPhotoTakenAt' => '2015-03-01', 'lastPhotoTakenAt' => '2018-07-09')
  end
end
