# frozen_string_literal: true

module Types
  # Base object class
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    private

    def authorize(record, action)
      context[:authorize].call(record, action)
    end
  end
end
