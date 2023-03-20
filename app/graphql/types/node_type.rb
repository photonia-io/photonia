# frozen_string_literal: true

module Types
  # Node type module
  module NodeType
    # Include the base interface
    include Types::BaseInterface
    # Add the `id` field
    include GraphQL::Types::Relay::NodeBehaviors
  end
end
