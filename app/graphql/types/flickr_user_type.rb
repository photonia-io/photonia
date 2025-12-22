# frozen_string_literal: true

module Types
  # GraphQL Flickr User Type
  class FlickrUserType < Types::BaseObject
    description 'A Flickr User'

    field :claimable, Boolean, 'Whether this Flickr user can be claimed by the current user', null: false
    field :claimed_by_user, Types::UserType, 'User who claimed this Flickr account', null: true
    field :iconfarm, String, 'Icon farm of the user\'s buddy image', null: true
    field :iconserver, String, 'Icon server of the user\'s buddy image', null: true
    field :nsid, String, 'NSID of the user', null: false
    field :profileurl, String, 'Flickr profile url of the user', null: true
    field :realname, String, 'Real name of the user', null: true
    field :username, String, 'Username of the user', null: true

    def claimable
      # If the flickr user was claimed return false
      return false if object.claimed_by_user_id.present?

      current_user = context[:current_user]
      return true unless current_user

      # If the current user has a pending or approved claim on ANY flickr_user return false
      !context[:user_has_claim]
    end
  end
end
