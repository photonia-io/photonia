# frozen_string_literal: true

require 'rails_helper'

# == Schema Information
#
# Table name: search_queries
#
#  id               :bigint           not null, primary key
#  filters          :jsonb
#  normalized_query :string
#  query            :text
#  results_count    :integer          default(0), not null
#  session_hash     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint
#
# Indexes
#
#  index_search_queries_on_created_at        (created_at)
#  index_search_queries_on_normalized_query  (normalized_query text_pattern_ops)
#  index_search_queries_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe SearchQuery do
  it 'has a valid factory' do
    expect(build(:search_query)).to be_valid
  end

  describe 'normalization' do
    it 'downcases and squishes the query into normalized_query' do
      search_query = create(:search_query, query: '  Lake   Sunset  ')

      expect(search_query.normalized_query).to eq('lake sunset')
    end

    it 'leaves normalized_query nil when query is blank' do
      search_query = create(:search_query, query: nil)

      expect(search_query.normalized_query).to be_nil
    end
  end

  describe 'user' do
    it 'is optional' do
      expect(build(:search_query, user: nil)).to be_valid
    end

    it 'can belong to a user' do
      user = create(:user)
      search_query = create(:search_query, user:)

      expect(search_query.reload.user).to eq(user)
    end
  end

  describe 'filters' do
    it 'round-trips a jsonb hash' do
      filters = { 'tags' => %w[sunset lake], 'isoMin' => 100 }
      search_query = create(:search_query, filters:)

      expect(search_query.reload.filters).to eq(filters)
    end

    it 'defaults to nil' do
      expect(create(:search_query).filters).to be_nil
    end
  end

  describe '.record' do
    it 'creates a search query with the given attributes' do
      user = create(:user)

      search_query = described_class.record(
        query: 'lake', results_count: 5, user:, session_hash: 'abc', filters: { 'tagsMode' => 'ANY' }
      )

      expect(search_query).to be_a(described_class)
      expect(search_query).to have_attributes(
        query: 'lake', results_count: 5, user:, session_hash: 'abc', filters: { 'tagsMode' => 'ANY' }
      )
    end

    it 'swallows an error, reports to Sentry and returns nil' do
      allow(described_class).to receive(:create!).and_raise(StandardError, 'boom')
      allow(Sentry).to receive(:capture_exception)

      result = described_class.record(query: 'lake', results_count: 0, user: nil, session_hash: 'abc')

      expect(result).to be_nil
      expect(Sentry).to have_received(:capture_exception)
    end
  end
end
