# frozen_string_literal: true

module Queries
  # Get the current user
  class CurrentUserQuery < BaseQuery
    type Types::UserType, null: false
    description 'Get the current user'

    def resolve
      raise GraphQL::ExecutionError, 'User not signed in' unless current_user

      current_user
    end
  end
end
