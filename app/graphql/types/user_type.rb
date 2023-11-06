# frozen_string_literal: true

module Types
  # GraphQL User Type
  class UserType < Types::BaseObject
    description 'A user'
    field :email, String, 'Email', null: true
    field :id, String, 'User ID', null: false
    field :timezone, Types::TimezoneType, 'Timezone', null: false
    field :admin, Boolean, 'Admin', null: false

    def timezone
      { name: @object.timezone }
    end
  end
end
