# frozen_string_literal: true

module Queries
  # Users Query
  class UsersQuery < BaseQuery
    description 'List all users (admin only)'

    type [Types::UserType], null: false

    def resolve
      authorize(User, :index?)
      User.order(created_at: :desc)
    end
  end
end
