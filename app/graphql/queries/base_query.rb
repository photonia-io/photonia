# frozen_string_literal: true

module Queries
  class BaseQuery < GraphQL::Schema::Resolver
    null false

    private

    def record_impression(object)
      context[:impressionist].call(object, 'graphql', unique: [:session_hash])
    end
  end
end
