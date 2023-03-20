# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    description 'A user'
    field :email, String, null: true
    field :id, String, null: true
  end
end
