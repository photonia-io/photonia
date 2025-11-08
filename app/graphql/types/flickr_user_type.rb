# frozen_string_literal: true

module Types
  # GraphQL Flickr User Type
  class FlickrUserType < Types::BaseObject
    description 'A Flickr User'

    field :nsid, String, 'NSID of the user', null: false
    field :username, String, 'Username of the user', null: true
    field :realname, String, 'Real name of the user', null: true
    field :profileurl, String, 'Flickr profile url of the user', null: true
    field :iconfarm, String, 'Icon farm of the user\'s buddy image', null: true
    field :iconserver, String, 'Icon server of the user\'s buddy image', null: true
    field :claimed_by_user, Types::UserType, 'User who claimed this Flickr account', null: true
    field :is_claimed, Boolean, 'Whether this Flickr user has been claimed', null: false
    field :current_user_has_claim, Boolean, 'Whether the current user has a pending or approved claim for this Flickr user', null: false

    def is_claimed
      object.claimed_by_user_id.present?
    end

    def current_user_has_claim
      current_user = context[:current_user]
      return false unless current_user

      # Check if the current user has any pending or approved claims for this Flickr user
      object.flickr_user_claims.exists?(user_id: current_user.id, status: ['pending', 'approved'])
    end
  end
end
