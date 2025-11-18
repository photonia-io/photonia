# frozen_string_literal: true

module Types
  # GraphQL AlbumShare Type
  class AlbumShareType < Types::BaseObject
    description 'An album share/invite'

    field :id, ID, 'ID of the album share', null: false
    field :email, String, 'Email address of the invitee', null: false
    field :is_registered_user, Boolean, 'Whether the email belongs to a registered user', null: false
    field :visitor_url, String, 'URL for visitor access (if not a registered user)', null: true
    field :shared_by_user_id, ID, 'ID of the user who created the share', null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, 'When the share was created', null: false

    def is_registered_user
      @object.user_id.present?
    end

    def visitor_url
      return nil if @object.user_id.present?
      return nil unless @object.visitor_token

      # Generate the URL for visitor access
      # This will be something like: /albums/{album_slug}?token={visitor_token}
      album_slug = @object.album.slug
      token = @object.visitor_token

      # Return the path - the frontend will construct the full URL
      "/albums/#{album_slug}?token=#{token}"
    end
  end
end
