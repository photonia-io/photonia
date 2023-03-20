# frozen_string_literal: true

module Types
  # Base input object class
  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class Types::BaseArgument
  end
end
