# frozen_string_literal: true

module Types
  # GraphQL Page Type
  class PageType < Types::BaseObject
    description 'A page'
    field :title, String, 'Title', null: false
    field :content, String, 'Content', null: false
  end
end
