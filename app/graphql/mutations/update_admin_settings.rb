# frozen_string_literal: true

module Mutations
  # Update admin settings. Every argument is optional - the admin UI is
  # split across tabs (General, Comments, System), and each tab submits only
  # the fields it owns, leaving the others untouched.
  class UpdateAdminSettings < Mutations::BaseMutation
    description 'Update admin settings'

    FIELDS = %i[
      site_name site_description site_tracking_code
      continue_with_google_enabled continue_with_facebook_enabled
      rekognition_enabled
      commenting_enabled photo_commenting_enabled album_commenting_enabled
    ].freeze

    argument :album_commenting_enabled, Boolean, 'Comments active on albums', required: false
    argument :commenting_enabled, Boolean, 'Comments active', required: false
    argument :continue_with_facebook_enabled, Boolean, 'Continue with Facebook active', required: false
    argument :continue_with_google_enabled, Boolean, 'Continue with Google active', required: false
    argument :photo_commenting_enabled, Boolean, 'Comments active on photos', required: false
    argument :rekognition_enabled, Boolean, 'Automatic Rekognition tagging active', required: false
    argument :site_description, String, 'Site description', required: false
    argument :site_name, String, 'Site name', required: false
    argument :site_tracking_code, String, 'Site tracking code', required: false

    type Types::AdminSettingsType, null: false

    def resolve(**provided)
      authorize(Setting, :update?)

      nulls = FIELDS.select { |field| provided.key?(field) && provided[field].nil? }
      raise GraphQL::ExecutionError, "Null not allowed for: #{nulls.join(', ')}" if nulls.any?

      FIELDS.each { |field| Setting.public_send("#{field}=", provided[field]) if provided.key?(field) }
      Setting
    end
  end
end
