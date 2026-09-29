# frozen_string_literal: true

module Types
  # Ascending or descending sort direction
  class SortDirection < Types::BaseEnum
    description 'Sort direction'

    value 'ASC', 'Ascending', value: 'asc'
    value 'DESC', 'Descending', value: 'desc'
  end
end
