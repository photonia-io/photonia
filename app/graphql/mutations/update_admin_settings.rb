# frozen_string_literal: true

module Mutations
  # Update admin settings
  class UpdateAdminSettings < Mutations::BaseMutation
    description 'Update admin settings'

    argument :commenting_enabled, Boolean, 'Comments active', required: true
    argument :continue_with_facebook_enabled, Boolean, 'Continue with Facebook active', required: true
    argument :continue_with_google_enabled, Boolean, 'Continue with Google active', required: true
    argument :rekognition_enabled, Boolean, 'Automatic Rekognition tagging active', required: true
    argument :site_description, String, 'Site description', required: true
    argument :site_name, String, 'Site name', required: true
    argument :site_tracking_code, String, 'Site tracking code', required: true

    type Types::AdminSettingsType, null: false

    def resolve(site_name:, site_description:, site_tracking_code:, continue_with_google_enabled:,
                continue_with_facebook_enabled:, rekognition_enabled:, commenting_enabled:)
      authorize(Setting, :update?)
      Setting.site_name = site_name
      Setting.site_description = site_description
      Setting.site_tracking_code = site_tracking_code
      Setting.continue_with_google_enabled = continue_with_google_enabled
      Setting.continue_with_facebook_enabled = continue_with_facebook_enabled
      Setting.rekognition_enabled = rekognition_enabled
      Setting.commenting_enabled = commenting_enabled
      Setting
    end
  end
end
