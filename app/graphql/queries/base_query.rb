# frozen_string_literal: true

module Queries
  # Base query class
  class BaseQuery < GraphQL::Schema::Resolver
    null false

    private

    def authorize(record, action)
      context[:authorize].call(record, action)
    end

    def current_user
      context[:current_user]
    end

    def record_impression(object)
      context[:impressionist].call(object, 'graphql', unique: [:session_hash])
    end

    def add_pagination_methods(collection, pagy)
      collection.define_singleton_method(:total_pages) { pagy.pages }
      collection.define_singleton_method(:current_page) { pagy.page }
      collection.define_singleton_method(:limit_value) { pagy.limit }
      collection.define_singleton_method(:total_count) { pagy.count }
    end

    def add_dummy_pagination_methods(collection)
      count = collection.count
      collection.define_singleton_method(:total_pages) { 1 }
      collection.define_singleton_method(:current_page) { 1 }
      collection.define_singleton_method(:limit_value) { count }
      collection.define_singleton_method(:total_count) { count }
    end
  end
end
