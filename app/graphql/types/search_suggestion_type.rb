# frozen_string_literal: true

module Types
  # One suggested search term/phrase, with how many past searches or photos
  # it matches (navbar suggestions dropdown, #1101)
  class SearchSuggestionType < Types::BaseObject
    description 'A suggested search phrase with a match count'

    field :count, Integer, 'Number of past searches or photos this matches', null: false
    field :text, String, 'The suggested search text', null: false
  end
end
