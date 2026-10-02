# frozen_string_literal: true

require 'rails_helper'

describe 'mostViewedOnDate Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:day) { Time.zone.today }
  let(:query) do
    <<~GQL
      query {
        mostViewedOnDate(date: "#{day.iso8601}", limit: 2) {
          photos { count photo { id } }
          albums { count album { id } }
        }
      }
    GQL
  end

  context 'when not an admin' do
    it 'returns NOT_FOUND' do
      sign_in(create(:user))
      post_query

      expect(response.parsed_body.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
      expect(response.parsed_body.dig('data', 'mostViewedOnDate')).to be_nil
    end
  end

  context 'when an admin' do
    let(:popular) { create(:photo) }
    let(:quiet) { create(:photo) }
    let(:hidden) { create(:photo, privacy: 'private') }
    let(:other_day) { create(:photo) }
    let(:album) { create(:album) }

    before do
      sign_in(create(:user, admin: true))
      noon = Time.zone.now.change(hour: 12)
      3.times { create(:impression, impressionable: popular, created_at: noon) }
      create(:impression, impressionable: quiet, created_at: noon)
      2.times { create(:impression, impressionable: hidden, created_at: noon) }
      5.times { create(:impression, impressionable: other_day, created_at: noon - 2.days) }
      create(:impression, impressionable: album, created_at: noon)
    end

    it 'returns the day top lists by slug, including private records, limited' do
      post_query
      data = response.parsed_body['data']['mostViewedOnDate']

      expect(data['photos']).to eq([
        { 'count' => 3, 'photo' => { 'id' => popular.slug } },
        { 'count' => 2, 'photo' => { 'id' => hidden.slug } }
      ])
      expect(data['albums']).to eq([{ 'count' => 1, 'album' => { 'id' => album.slug } }])
    end
  end
end
