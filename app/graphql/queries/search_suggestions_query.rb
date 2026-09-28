# frozen_string_literal: true

module Queries
  # Suggestions for the navbar search box's dropdown (#1101): popular past
  # searches, precomputed suggestion words, matching photos, and (signed-in
  # users, blank query only) the user's own recent searches. Never recorded
  # itself - only an actually submitted search is (BaseQuery#record_search).
  class SearchSuggestionsQuery < BaseQuery
    description 'Find search suggestions for a query prefix'

    type Types::SearchSuggestionsType, null: false

    argument :query, String, 'Prefix typed so far', required: false
    argument :limit, Integer, 'Max results per suggestion group', required: false

    DEFAULT_LIMIT = 5
    MAX_LIMIT = 10
    POPULAR_SEARCH_WINDOW = 12
    MIN_POPULAR_SEARCH_COUNT = 2
    PHOTO_LIMIT = 3
    RECENT_LIMIT = 5

    Suggestions = Struct.new(:searches, :terms, :photos, :recent)
    Suggestion = Struct.new(:text, :count)

    def resolve(query: nil, limit: nil)
      prefix = query.to_s.strip
      effective_limit = (limit || DEFAULT_LIMIT).clamp(0, MAX_LIMIT)

      Suggestions.new(
        popular_searches(prefix, effective_limit),
        suggestion_terms(prefix, effective_limit),
        matching_photos(prefix),
        recent_searches(prefix)
      )
    end

    private

    def popular_searches(prefix, limit)
      return [] if prefix.blank?

      rows = SearchQuery.where(created_at: POPULAR_SEARCH_WINDOW.months.ago..)
                        .where('results_count > 0')
                        .where('normalized_query LIKE ?', "#{sanitize_like(prefix.downcase)}%")
                        .group(:normalized_query)
                        .having('COUNT(*) >= ?', MIN_POPULAR_SEARCH_COUNT)
                        .order(Arel.sql('COUNT(*) DESC, MAX(created_at) DESC'))
                        .limit(limit)
                        .count

      rows.map { |normalized_query, count| Suggestion.new(normalized_query, count) }
    end

    def suggestion_terms(prefix, limit)
      return [] if prefix.blank?

      SearchTerm.where('term LIKE unaccent(lower(?)) || ?', sanitize_like(prefix), '%')
                .order(photos_count: :desc)
                .limit(limit)
                .map { |term| Suggestion.new(term.term, term.photos_count) }
    end

    def matching_photos(prefix)
      return [] if prefix.blank?

      Pundit.policy_scope(current_user, Photo.unscoped)
            .where('title ILIKE ?', "%#{sanitize_like(prefix)}%")
            .order(Arel.sql('impressions_count DESC'))
            .limit(PHOTO_LIMIT)
    end

    # Only offered when there's nothing typed yet - once there's a prefix,
    # the other three groups are more useful than the user's own history.
    def recent_searches(prefix)
      return [] if prefix.present? || current_user.nil?

      current_user.search_queries
                  .where.not(normalized_query: nil)
                  .order(created_at: :desc)
                  .limit(50)
                  .pluck(:normalized_query)
                  .uniq
                  .first(RECENT_LIMIT)
    end
  end
end
