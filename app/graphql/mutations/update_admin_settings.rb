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
      homepage_spotlight_album_id
    ].freeze
    HOMEPAGE_FIELDS = Setting::HOMEPAGE_SECTIONS.map { |section| :"homepage_#{section}_enabled" }.freeze
    ALL_FIELDS = (FIELDS + HOMEPAGE_FIELDS).freeze

    argument :album_commenting_enabled, Boolean, 'Comments active on albums', required: false
    argument :commenting_enabled, Boolean, 'Comments active', required: false
    argument :continue_with_facebook_enabled, Boolean, 'Continue with Facebook active', required: false
    argument :continue_with_google_enabled, Boolean, 'Continue with Google active', required: false
    argument :photo_commenting_enabled, Boolean, 'Comments active on photos', required: false
    argument :rekognition_enabled, Boolean, 'Automatic Rekognition tagging active', required: false
    argument :site_description, String, 'Site description', required: false
    argument :site_name, String, 'Site name', required: false
    argument :site_tracking_code, String, 'Site tracking code', required: false
    argument :homepage_spotlight_album_id, String, 'Slug of the spotlighted album, blank for the latest album', required: false
    HOMEPAGE_FIELDS.each do |field|
      argument field, Boolean, 'Show this section on the homepage', required: false
    end

    type Types::AdminSettingsType, null: false

    def resolve(**provided)
      authorize(Setting, :update?)

      nulls = ALL_FIELDS.select { |field| provided.key?(field) && provided[field].nil? }
      raise GraphQL::ExecutionError, "Null not allowed for: #{nulls.join(', ')}" if nulls.any?

      validate_spotlight_album(provided[:homepage_spotlight_album_id])

      ALL_FIELDS.each { |field| Setting.public_send("#{field}=", provided[field]) if provided.key?(field) }
      Setting
    end

    private

    # Only an album visitors can actually see (public, with public photos)
    def validate_spotlight_album(slug)
      return if slug.blank?
      return if Album.where('albums.public_photos_count > 0').exists?(slug:)

      raise GraphQL::ExecutionError, 'Spotlight album must be a public album with public photos'
    end
  end
end
