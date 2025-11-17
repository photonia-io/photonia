# frozen_string_literal: true

module Queries
  # User Query
  class UserQuery < BaseQuery
    description 'Find a user by ID (admin only)'

    type Types::UserType, null: false

    argument :id, String, 'User ID', required: true

    def resolve(id:)
      authorize(User, :show?)
      User.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, 'User not found'
    end
  end
end
