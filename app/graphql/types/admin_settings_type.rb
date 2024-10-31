# frozen_string_literal: true

module Types
  # GraphQL Admin Settings Type
  class AdminSettingsType < Types::BaseObject
    description 'Admin Settings'
    field :id, String, null: false
    field :site_name, String, null: false
    field :site_description, String, null: false
    field :site_tracking_code, String, null: false
    field :continue_with_google_enabled, Boolean, null: false
    field :continue_with_facebook_enabled, Boolean, null: false

    def id
      'admin-settings'
    end
  end
end
