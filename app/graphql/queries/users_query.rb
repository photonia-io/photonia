# frozen_string_literal: true

module Queries
  # Users Query
  class UsersQuery < BaseQuery
    description 'List all users by page (admin only)'

    type Types::UserType.collection_type, null: false

    argument :page, Integer, 'Page number', required: false

    def resolve(page: nil)
      authorize(User, :index?)

      pagy, records = context[:pagy].call(User.order(created_at: :desc), page:)
      add_pagination_methods(records, pagy)
      records
    end
  end
end
