# frozen_string_literal: true

module Types
  # Grouped suggestions for the navbar search box's dropdown (#1101):
  # popular past searches, precomputed suggestion words, matching photos,
  # and (signed-in users, blank query only) the user's own recent searches.
  class SearchSuggestionsType < Types::BaseObject
    description 'Grouped search suggestions for the navbar dropdown'

    field :photos, [Types::PhotoType], 'Photos whose title matches', null: false
    field :recent, [String], "The signed-in user's own recent searches", null: false
    field :searches, [Types::SearchSuggestionType], 'Popular past searches matching the prefix', null: false
    field :terms, [Types::SearchSuggestionType], 'Precomputed suggestion words matching the prefix', null: false
  end
end
