module Types
  class UserType < Types::BaseObject
    description 'A user'
    field :id, String, null: true
    field :email, String, null: true
  end
end