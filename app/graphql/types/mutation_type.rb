module Types
  class MutationType < GraphQL::Schema::Object
    field :sign_in, UserType, null: true do
      description 'Sign in'
      argument :email, String, required: true
      argument :password, String, required: true
    end

    def sign_in(email:, password:)
      user = User.find_for_database_authentication(email: email)
      return unless user&.valid_password?(password)
      context[:sign_in].call(:user, user)
      user
    end

    field :sign_out, UserType, null: true do
      description 'Sign out'
    end

    def sign_out
      context[:sign_out].call
      user = {
        id: nil,
        email: nil
      }
    end
  end
end
