# frozen_string_literal: true

module Mutations
  class ContinueWithFacebook < Mutations::BaseMutation
    description 'Sign up or sign in with Facebook'

    argument :access_token, String, 'Facebook access token', required: true
    argument :signed_request, String, 'Facebook signed request', required: true

    type Types::UserType, null: true

    def resolve(access_token:, signed_request:)
      raise 'Continue with Facebook is disabled' if Setting.continue_with_facebook_enabled == false

      cwfs = ContinueWithFacebookService.new(access_token, signed_request)
      facebook_user_info = cwfs.facebook_user_info

      user, created = find_or_create_facebook_user(facebook_user_info)
      notify_admins_of_new_user(user) if created
      context[:sign_in].call(:user, user)
      user
    end

    private

    def find_or_create_facebook_user(facebook_user_info)
      email = facebook_user_info['email']
      raise GraphQL::ExecutionError, 'Facebook account is missing email. Please grant the email permission.' if email.blank?

      User.find_or_create_from_provider(
        email: email,
        provider: 'facebook',
        first_name: facebook_user_info['first_name'],
        last_name: facebook_user_info['last_name'],
        display_name: facebook_user_info['name'],
        facebook_user_id: facebook_user_info['id']
      )
    end

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
