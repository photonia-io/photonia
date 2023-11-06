# frozen_string_literal: true

module Types
  # GraphQL Admin Settings Type
  class AdminSettingsType < Types::BaseObject
    description 'Admin Settings'
    field :site_name, String, null: false
    field :site_description, String, null: false
  end
end
