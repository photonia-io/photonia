# frozen_string_literal: true

require 'rails_helper'

describe 'photos Query' do
  include Devise::Test::IntegrationHelpers

  context 'when using the paginated mode' do
    describe 'paging' do
      subject(:post_query) { post '/graphql', params: { query: } }

      let(:photo_count) { 3 }
      let(:query) do
        <<~GQL
          query {
            photos(page: 1) {
              metadata {
                totalPages
                totalCount
                currentPage
                limitValue
              }
              collection {
                id
              }
            }
          }
        GQL
      end

      before do
        create_list(:photo, photo_count)
      end

      it 'returns the correct metadata' do
        post_query

        expect(response.parsed_body['data']['photos']['metadata']).to include(
          'totalPages' => 1,
          'totalCount' => photo_count,
          'currentPage' => 1,
          'limitValue' => 20
        )
      end

      it 'returns the correct number of photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
      end
    end

    describe 'a collapsed album' do
      subject(:post_query) { post '/graphql', params: { query: } }

      let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }
      let!(:cover) { create(:photo, privacy: 'public') }
      let!(:other) { create(:photo, privacy: 'public') }

      let(:query) do
        <<~GQL
          query {
            photos(page: 1) {
              collection {
                id
                feedAlbum {
                  id
                  title
                  photosCount
                }
              }
            }
          }
        GQL
      end

      before do
        album.photos << cover
        album.photos << other
        album.maintenance
      end

      it 'excludes the hidden photos and marks the cover with feedAlbum' do
        post_query

        collection = response.parsed_body['data']['photos']['collection']
        ids = collection.map { |p| p['id'] }

        expect(ids).to contain_exactly(cover.slug)

        feed_album = collection.first['feedAlbum']
        expect(feed_album).to include('id' => album.slug, 'photosCount' => 2)
      end

      it 'still includes the hidden photos when searching' do
        cover.update!(title: 'Race day cover')
        other.update!(title: 'Race day bystander')

        post '/graphql', params: {
          query: <<~GQL
            query {
              photos(page: 1, query: "Race day") {
                collection { id feedAlbum { id } }
              }
            }
          GQL
        }

        collection = response.parsed_body['data']['photos']['collection']
        ids = collection.map { |p| p['id'] }
        expect(ids).to contain_exactly(cover.slug, other.slug)
        expect(collection.map { |p| p['feedAlbum'] }).to all(be_nil)
      end
    end

    describe 'search' do
      subject(:post_query) { post '/graphql', params: { query: } }

      let!(:match_photo)      { create(:photo, title: 'Sunset over Lake') }
      let!(:non_match_photo)  { create(:photo, title: 'Forest Trail') }

      let(:query) do
        <<~GQL
          query {
            photos(page: 1, query: "Lake") {
              metadata {
                totalPages
                totalCount
                currentPage
                limitValue
              }
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'filters photos using the search query' do
        post_query

        data = response.parsed_body['data']['photos']
        expect(data['metadata']).to include(
          'totalPages' => 1,
          'totalCount' => 1,
          'currentPage' => 1,
          'limitValue' => 20
        )

        ids = data['collection'].map { |p| p['id'] }
        expect(ids).to eq([match_photo.slug])
      end

      it 'records the search in a search_queries row with the query, results_count, and session_hash' do
        expect { post_query }.to change(SearchQuery, :count).by(1)

        search_query = SearchQuery.last
        expect(search_query.query).to eq('Lake')
        expect(search_query.results_count).to eq(1)
        expect(search_query.session_hash).to be_present
        expect(search_query.filters).to be_nil
        expect(search_query.user).to be_nil
      end

      it 'sets the user on the recorded search when signed in' do
        user = create(:user)
        sign_in(user)

        post_query

        expect(SearchQuery.last.user).to eq(user)
      end
    end

    describe 'recording (unrecorded cases)' do
      subject(:post_query) { post '/graphql', params: { query: } }

      before { create_list(:photo, 2) }

      context 'when there is no query (the plain photo list)' do
        let(:query) do
          <<~GQL
            query {
              photos(page: 1) {
                collection { id }
              }
            }
          GQL
        end

        it 'does not create a search_queries row' do
          expect { post_query }.not_to change(SearchQuery, :count)
        end
      end

      context 'when paging past page 1 of a search' do
        let(:query) do
          <<~GQL
            query {
              photos(page: 2, query: "photo") {
                collection { id }
              }
            }
          GQL
        end

        it 'does not create a search_queries row' do
          expect { post_query }.not_to change(SearchQuery, :count)
        end
      end
    end
  end

  describe '#710 matching albums and tags above the results' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:query) do
      <<~GQL
        query {
          matchingAlbums: albums(mode: "simple", query: "lake", limit: 8) {
            collection { id title }
          }
          matchingTags: tags(query: "lake", limit: 12) {
            id
            name
          }
        }
      GQL
    end

    it 'returns albums matching the query' do
      photo = create(:photo)
      album = create(:album, title: 'Lake trip')
      album.photos << photo
      album.maintenance

      post_query

      titles = response.parsed_body.dig('data', 'matchingAlbums', 'collection').map { |a| a['title'] }
      expect(titles).to eq(['Lake trip'])
    end

    it "hides a private album's match from a visitor" do
      photo = create(:photo, privacy: 'private')
      album = create(:album, title: 'Lake trip', privacy: 'private')
      album.photos << photo
      album.maintenance

      post_query

      expect(response.parsed_body.dig('data', 'matchingAlbums', 'collection')).to be_empty
    end

    it 'returns tags matching the query' do
      photo = create(:photo)
      TaggingSource.find_by(name: 'Flickr').tag(photo, with: 'lake,mountains', on: :tags)

      post_query

      names = response.parsed_body.dig('data', 'matchingTags').map { |t| t['name'] }
      expect(names).to eq(['lake'])
    end
  end

  context 'when using the simple mode' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:photo_count) { 3 }

    # Set a lower SIMPLE_MODE_MAX_LIMIT for tests to avoid creating many records
    before do
      stub_const('Queries::PhotosQuery::SIMPLE_MODE_MAX_LIMIT', 5)
      create_list(:photo, 3)
    end

    context 'when there are no parameters' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns all photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
      end
    end

    context 'when there is a limit parameter (and is below the maximum allowed limit)' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", limit: 2) {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns the correct number of photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(2)
      end
    end

    context 'when fetchType is random' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", fetchType: "random") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns the correct number of photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
      end
    end

    context 'when fetchType is feed' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", fetchType: "feed", offset: 1, limit: 2) {
              collection {
                id
                feedAlbum { id photosCount }
              }
            }
          }
        GQL
      end

      before { Photo.unscoped.destroy_all }

      it 'skips hidden photos, orders newest first and applies the offset' do
        newest = create(:photo, posted_at: 1.day.ago)
        second = create(:photo, posted_at: 2.days.ago)
        third = create(:photo, posted_at: 3.days.ago)
        create(:photo, posted_at: 1.hour.ago, hidden_from_feed: true)
        create(:photo, posted_at: 4.days.ago)

        post_query

        ids = response.parsed_body['data']['photos']['collection'].map { |p| p['id'] }
        expect(ids).to eq([second.slug, third.slug])
        expect(ids).not_to include(newest.slug)
      end

      it 'marks the cover of a collapsed album with feedAlbum' do
        album = create(:album, sorting_type: 'manual', collapsed_in_feed: true)
        cover = create(:photo, posted_at: 2.days.ago)
        album.photos << cover
        album.photos << create(:photo, posted_at: 2.days.ago)
        album.maintenance
        create(:photo, posted_at: 1.day.ago)

        post_query

        collection = response.parsed_body['data']['photos']['collection']
        expect(collection.first).to include('id' => cover.slug, 'feedAlbum' => include('id' => album.slug, 'photosCount' => 2))
      end
    end

    describe 'taken-date fetch types' do
      include ActiveSupport::Testing::TimeHelpers

      around { |example| travel_to(Time.zone.local(2026, 10, 15, 12)) { example.run } }

      before { Photo.unscoped.destroy_all }

      def taken_photo(taken_at, source: 'user', precision: 'minute', approximate: false, **attrs)
        create(:photo, **attrs).tap do |photo|
          photo.update_columns(taken_at:, taken_at_source: source, taken_at_precision: precision,
                               taken_at_approximate: approximate)
        end
      end

      def fetch_ids(fetch_type)
        post '/graphql', params: {
          query: %(query { photos(mode: "simple", fetchType: "#{fetch_type}") { collection { id } } })
        }
        response.parsed_body['data']['photos']['collection'].map { |p| p['id'] }
      end

      describe 'on_this_day' do
        it 'returns photos taken on today\'s month and day in earlier years only' do
          match = taken_photo(Time.zone.local(2019, 10, 15, 9))
          taken_photo(Time.zone.local(2026, 10, 15, 9))
          taken_photo(Time.zone.local(2019, 10, 16, 9))
          taken_photo(Time.zone.local(2019, 11, 15, 9))

          expect(fetch_ids('on_this_day')).to eq([match.slug])
        end

        it 'skips unknown-source, approximate, month-precision and non-public photos' do
          taken_photo(Time.zone.local(2019, 10, 15), source: 'unknown')
          taken_photo(Time.zone.local(2019, 10, 15), approximate: true)
          taken_photo(Time.zone.local(2019, 10, 15), precision: 'month')
          taken_photo(Time.zone.local(2019, 10, 15), privacy: 'private')

          expect(fetch_ids('on_this_day')).to be_empty
        end
      end

      describe 'this_month' do
        it 'returns earlier years of this month, excluding today\'s day and this year' do
          other_day = taken_photo(Time.zone.local(2019, 10, 3))
          month_only = taken_photo(Time.zone.local(2018, 10, 15), precision: 'month')
          taken_photo(Time.zone.local(2019, 10, 15))
          taken_photo(Time.zone.local(2026, 10, 3))
          taken_photo(Time.zone.local(2019, 9, 3))

          expect(fetch_ids('this_month')).to contain_exactly(other_day.slug, month_only.slug)
        end
      end
    end

    describe 'view-based fetch types' do
      before { Photo.unscoped.destroy_all }

      def fetch_ids(fetch_type, limit: nil)
        args = limit ? ", limit: #{limit}" : ''
        post '/graphql', params: {
          query: %(query { photos(mode: "simple", fetchType: "#{fetch_type}"#{args}) { collection { id } } })
        }
        response.parsed_body['data']['photos']['collection'].map { |p| p['id'] }
      end

      def view(photo, at: Time.current)
        Impression.create!(impressionable_type: 'Photo', impressionable_id: photo.id, created_at: at)
      end

      describe 'trending' do
        it 'ranks by impressions in the last 7 days, ignoring older ones and non-public photos' do
          popular = create(:photo)
          modest = create(:photo)
          stale = create(:photo)
          hidden = create(:photo, privacy: 'private')
          3.times { view(popular) }
          view(modest)
          5.times { view(stale, at: 8.days.ago) }
          4.times { view(hidden) }

          expect(fetch_ids('trending')).to eq([popular.slug, modest.slug])
        end

        it 'is empty when nothing was viewed this week' do
          create(:photo)

          expect(fetch_ids('trending')).to be_empty
        end
      end

      describe 'most_viewed' do
        it 'orders by local plus Flickr views' do
          low = create(:photo, impressions_count: 1, flickr_impressions_count: 2)
          high = create(:photo, impressions_count: 5, flickr_impressions_count: 100)
          mid = create(:photo, impressions_count: 50, flickr_impressions_count: 0)

          expect(fetch_ids('most_viewed')).to eq([high.slug, mid.slug, low.slug])
        end
      end

      describe 'least_viewed' do
        it 'draws only from the least viewed photos' do
          stub_const('Queries::PhotosQuery::HIDDEN_GEMS_POOL', 2)
          gems = [create(:photo, impressions_count: 0), create(:photo, impressions_count: 1)]
          create(:photo, impressions_count: 500)
          create(:photo, flickr_impressions_count: 900)

          expect(fetch_ids('least_viewed')).to match_array(gems.map(&:slug))
        end
      end
    end

    context 'when limit exceeds maximum allowed limit' do
      # We're requesting 6 photos because for tests the SIMPLE_MODE_MAX_LIMIT is set 5
      # Normally SIMPLE_MODE_MAX_LIMIT is 100
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", limit: 6) {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'enforces the maximum limit of 5 (configured for tests)' do
        # Create 6 photos to test the limit enforcement (SIMPLE_MODE_MAX_LIMIT is 5 in tests)
        create_list(:photo, 6)

        post '/graphql', params: { query: }

        # Should return exactly 5 photos even though 6 was requested
        expect(response.parsed_body['data']['photos']['collection'].length).to eq(5)
      end
    end

    context 'when no limit is specified' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'applies the default maximum limit of 5 (configured for tests)' do
        # Create 6 photos to test the default limit (SIMPLE_MODE_MAX_LIMIT is 5 in tests)
        create_list(:photo, 6)

        post '/graphql', params: { query: }

        # Should return exactly 5 photos by default
        expect(response.parsed_body['data']['photos']['collection'].length).to eq(5)
      end
    end
  end
end
