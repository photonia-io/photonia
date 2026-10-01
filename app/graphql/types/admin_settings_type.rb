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
    field :rekognition_enabled, Boolean, null: false
    field :commenting_enabled, Boolean, null: false
    field :photo_commenting_enabled, Boolean, null: false
    field :album_commenting_enabled, Boolean, null: false


    Setting::HOMEPAGE_SECTIONS.each do |section|
      field :"homepage_#{section}_enabled", Boolean, "Show the #{section.to_s.humanize.downcase} section on the homepage", null: false
    end
    field :homepage_spotlight_album_id, String, 'Slug of the spotlighted album, blank for the latest album', null: false
    field :spotlight_album_choices, [AlbumType], 'Albums that can be spotlighted on the homepage', null: false

    def spotlight_album_choices
      Album.where('albums.public_photos_count > 0').order(:title)
    end

    def id
      'admin-settings'
    end
  end
end
