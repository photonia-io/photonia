# frozen_string_literal: true

module Mutations
  class ContinueWithGoogle < Mutations::BaseMutation
    description 'Sign up or sign in with Google'

    argument :credential, String, 'Google credential JWT', required: true

    type Types::UserType, null: true

    def resolve(credential:)
      raise 'Continue with Google is disabled' if Setting.continue_with_google_enabled == false

      payload = Google::Auth::IDTokens.verify_oidc(
        credential,
        aud: Setting.google_client_id
      )

      return unless payload && payload['email_verified']

      user, created = User.find_or_create_from_provider(
        email: payload['email'],
        provider: 'google',
        first_name: payload['given_name'],
        last_name: payload['family_name'],
        display_name: payload['name']
      )

      notify_admins_of_new_user(user) if created
      context[:sign_in].call(:user, user)
      user
    end

    private

    def notify_admins_of_new_user(user)
      AdminMailer.with(
        provider: user.signup_provider.capitalize,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        admin_emails: User.admins.pluck(:email)
      ).new_provider_user.deliver_later
    end
  end
end
