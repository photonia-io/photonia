# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'albumSpotlight Query' do
  include Devise::Test::IntegrationHelpers

  subject(:spotlight) do
    post '/graphql', params: { query: }
    response.parsed_body.dig('data', 'albumSpotlight')
  end

  let(:query) { 'query { albumSpotlight { id title } }' }

  def public_album(title, created_at: Time.current, **attrs)
    create(:album, title:, created_at:, **attrs).tap do |album|
      album.photos << create(:photo)
      album.maintenance
    end
  end

  it 'is the picked album' do
    picked = public_album('Picked', created_at: 3.days.ago)
    public_album('Newest')
    Setting.homepage_spotlight_album_id = picked.slug

    expect(spotlight).to eq('id' => picked.slug, 'title' => 'Picked')
  end

  it 'falls back to the newest album when none is picked' do
    public_album('Older', created_at: 3.days.ago)
    newest = public_album('Newest')

    expect(spotlight).to eq('id' => newest.slug, 'title' => 'Newest')
  end

  it 'falls back to the newest album when the pick is no longer public' do
    picked = public_album('Picked', created_at: 3.days.ago)
    newest = public_album('Newest')
    Setting.homepage_spotlight_album_id = picked.slug
    picked.update!(privacy: 'private')

    expect(spotlight).to eq('id' => newest.slug, 'title' => 'Newest')
  end

  it 'is null when there is no visible album' do
    expect(spotlight).to be_nil
  end
end
