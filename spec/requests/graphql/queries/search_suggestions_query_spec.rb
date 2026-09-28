# frozen_string_literal: true

require 'rails_helper'

describe 'searchSuggestions Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  include_context 'with auth actors'

  def query_for(query: nil, limit: nil)
    args = [query && "query: #{query.to_json}", limit && "limit: #{limit}"].compact.join(', ')
    args = "(#{args})" if args.present?
    <<~GQL
      query {
        searchSuggestions#{args} {
          searches { text count }
          terms { text count }
          photos { id }
          recent
        }
      }
    GQL
  end

  def suggestions
    response.parsed_body.dig('data', 'searchSuggestions')
  end

  describe 'searches' do
    let(:query) { query_for(query: 'lak') }

    it 'suggests a popular normalized query matching the prefix' do
      create_list(:search_query, 2, query: 'Lake sunset', results_count: 3)

      post_query

      expect(suggestions['searches']).to contain_exactly({ 'text' => 'lake sunset', 'count' => 2 })
    end

    it "excludes a search that hasn't been made at least twice" do
      create(:search_query, query: 'Lake sunset', results_count: 3)

      post_query

      expect(suggestions['searches']).to be_empty
    end

    it 'excludes a search that returned no results' do
      create_list(:search_query, 2, query: 'Lake sunset', results_count: 0)

      post_query

      expect(suggestions['searches']).to be_empty
    end

    it "excludes a search older than #{Queries::SearchSuggestionsQuery::POPULAR_SEARCH_WINDOW} months" do
      too_old = (Queries::SearchSuggestionsQuery::POPULAR_SEARCH_WINDOW + 1).months.ago
      create_list(:search_query, 2, query: 'Lake sunset', results_count: 3, created_at: too_old)

      post_query

      expect(suggestions['searches']).to be_empty
    end

    it 'excludes a search not matching the prefix' do
      create_list(:search_query, 2, query: 'Mountain view', results_count: 3)

      post_query

      expect(suggestions['searches']).to be_empty
    end
  end

  describe 'terms' do
    let(:query) { query_for(query: 'lak') }

    it 'suggests a precomputed term matching the prefix' do
      create(:search_term, term: 'lake', photos_count: 4)
      create(:search_term, term: 'mountain', photos_count: 9)

      post_query

      expect(suggestions['terms']).to contain_exactly({ 'text' => 'lake', 'count' => 4 })
    end

    it 'matches regardless of accents or case in the typed prefix' do
      create(:search_term, term: 'cafe', photos_count: 1)

      post '/graphql', params: { query: query_for(query: 'CAF') }

      expect(suggestions['terms']).to contain_exactly({ 'text' => 'cafe', 'count' => 1 })
    end
  end

  describe 'photos' do
    let(:query) { query_for(query: 'lak') }

    it 'suggests a matching photo title' do
      match = create(:photo, title: 'A lake at dawn')
      create(:photo, title: 'Something else')

      post_query

      expect(suggestions['photos'].pluck('id')).to contain_exactly(match.slug)
    end

    it "hides a private photo's title from a stranger" do
      create(:photo, user: owner, privacy: 'private', title: 'Lake house')

      sign_in(stranger)
      post_query

      expect(suggestions['photos']).to be_empty
    end
  end

  describe 'recent' do
    let(:user) { create(:user) }

    it "returns the signed-in user's own recent searches when the query is blank" do
      create(:search_query, user:, query: 'lake')
      create(:search_query, user:, query: 'mountain')
      create(:search_query, query: 'other user search')

      sign_in(user)
      post '/graphql', params: { query: query_for }

      expect(response.parsed_body.dig('data', 'searchSuggestions', 'recent')).to contain_exactly('lake', 'mountain')
    end

    it 'is empty once a prefix has been typed' do
      create(:search_query, user:, query: 'lake')

      sign_in(user)
      post '/graphql', params: { query: query_for(query: 'lak') }

      expect(response.parsed_body.dig('data', 'searchSuggestions', 'recent')).to be_empty
    end

    it 'is empty for a visitor' do
      post '/graphql', params: { query: query_for }

      expect(response.parsed_body.dig('data', 'searchSuggestions', 'recent')).to be_empty
    end
  end

  describe 'no query recorded' do
    let(:query) { query_for(query: 'lak') }

    it 'never records a search_queries row for a suggestions lookup' do
      expect { post_query }.not_to change(SearchQuery, :count)
    end
  end
end
