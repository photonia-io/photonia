# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'homepageStats Query' do
  subject(:stats) do
    post '/graphql', params: { query: }
    response.parsed_body.dig('data', 'homepageStats')
  end

  let(:query) do
    <<~GQL
      query {
        homepageStats {
          photosCount
          albumsCount
          viewsCount
          firstYear
          lastYear
          years { year count }
        }
      }
    GQL
  end

  def photo_taken(year, **attrs)
    create(:photo, **attrs).tap { |photo| photo.update_columns(taken_at: Time.zone.local(year, 6, 1)) }
  end

  it 'counts only public photos and albums, with per-year counts newest first' do
    photo_taken(2009)
    photo_taken(2009)
    photo_taken(2015, impressions_count: 10, flickr_impressions_count: 5)
    photo_taken(2020, privacy: 'private')
    album = create(:album)
    album.photos << Photo.first
    album.maintenance
    create(:album).maintenance

    expect(stats).to include(
      'photosCount' => 3,
      'albumsCount' => 1,
      'viewsCount' => 15,
      'firstYear' => 2009,
      'lastYear' => 2015,
      'years' => [{ 'year' => 2015, 'count' => 1 }, { 'year' => 2009, 'count' => 2 }]
    )
  end

  it 'handles an empty archive' do
    expect(stats).to include('photosCount' => 0, 'firstYear' => nil, 'years' => [])
  end
end
