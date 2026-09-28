# frozen_string_literal: true

require 'rails_helper'

# previousPhoto/nextPhoto are plain chronological order, unaware of
# hidden_from_feed - that flag only governs list-type surfaces (the paginated
# grid, the homepage's latest photo, the RSS feed). The consecutive-photos
# constraint on a collapsed album (Album#feed_gap_photo) guarantees no other
# photo was posted in between its members, so this gives a correct in-album
# carousel for a hidden photo for free, with no special-casing and no dead end.
describe 'photo navigation around a collapsed album' do
  subject(:post_query) do
    post '/graphql', params: { query: query }
    response.parsed_body.dig('data', 'photo')
  end

  let(:now) { Time.zone.now.change(usec: 0) }
  let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }

  let(:cover)   { create(:photo, posted_at: now) }
  let(:hidden)  { create(:photo, posted_at: now + 1.hour) }
  let!(:beyond) { create(:photo, posted_at: now + 2.hours) }

  before do
    album.photos << cover
    album.photos << hidden
    album.maintenance
  end

  def query_for(photo)
    <<~GQL
      query {
        photo(id: "#{photo.slug}") {
          id
          previousPhoto { id }
          nextPhoto { id }
        }
      }
    GQL
  end

  context 'when querying from the cover' do
    let(:query) { query_for(cover) }

    it "steps into the album's own hidden photo, not past it" do
      data = post_query

      expect(data['id']).to eq(cover.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(hidden.slug.to_s)
    end
  end

  context 'when querying from the hidden photo' do
    let(:query) { query_for(hidden) }

    it 'has real navigation both ways, with no special-casing' do
      data = post_query

      expect(data['id']).to eq(hidden.slug.to_s)
      expect(data.dig('previousPhoto', 'id')).to eq(cover.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(beyond.slug.to_s)
    end
  end

  it 'round-trips: next from the cover, then previous from there, returns to the cover' do
    post '/graphql', params: { query: query_for(cover) }
    next_id = response.parsed_body.dig('data', 'photo', 'nextPhoto', 'id')
    expect(next_id).to eq(hidden.slug.to_s)

    post '/graphql', params: { query: query_for(hidden) }
    previous_id = response.parsed_body.dig('data', 'photo', 'previousPhoto', 'id')
    expect(previous_id).to eq(cover.slug.to_s)
  end
end
