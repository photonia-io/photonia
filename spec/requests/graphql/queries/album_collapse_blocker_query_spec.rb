# frozen_string_literal: true

require 'rails_helper'

describe 'album Query - collapseBlocker' do
  include Devise::Test::IntegrationHelpers
  include_context 'with auth actors'

  subject(:post_query) do
    post '/graphql', params: { query: query }
    response.parsed_body.dig('data', 'album', 'collapseBlocker')
  end

  let(:album) { create(:album, user: owner, sorting_type: 'manual') }

  let(:query) do
    <<~GQL
      query {
        album(id: "#{album.slug}") {
          id
          collapseBlocker
        }
      }
    GQL
  end

  context 'when the album has no public photos' do
    before { sign_in(owner) }

    it "explains that a public photo is needed" do
      expect(post_query).to eq('Add at least one public photo before collapsing this album')
    end
  end

  context 'when the album has a gap' do
    before do
      now = Time.zone.now.change(usec: 0)
      first = create(:photo, user: owner, privacy: 'public', posted_at: now)
      create(:photo, posted_at: now + 30.minutes)
      last = create(:photo, user: owner, privacy: 'public', posted_at: now + 1.hour)
      album.photos << first
      album.photos << last
      album.maintenance
      sign_in(owner)
    end

    it 'reports the album as non-consecutive' do
      expect(post_query).to eq("Can't collapse: the photos of this album were not posted consecutively")
    end
  end

  context 'when the album is collapsible' do
    before do
      album.photos << create(:photo, user: owner, privacy: 'public')
      album.maintenance
      sign_in(owner)
    end

    it 'is nil' do
      expect(post_query).to be_nil
    end
  end

  context 'when signed in as a stranger' do
    before do
      album.photos << create(:photo, user: owner, privacy: 'private')
      album.maintenance
      sign_in(stranger)
    end

    it 'is nil, even though the owner would see a blocker' do
      expect(post_query).to be_nil
    end
  end

  context 'when not signed in' do
    before do
      album.photos << create(:photo, user: owner, privacy: 'private')
      album.maintenance
    end

    it 'is nil' do
      expect(post_query).to be_nil
    end
  end
end
