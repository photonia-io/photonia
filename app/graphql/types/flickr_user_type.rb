# frozen_string_literal: true

module Types
  # GraphQL Flickr User Type
  class FlickrUserType < Types::BaseObject
    description 'A Flickr User'

    field :nsid, String, 'NSID of the user', null: false
    field :username, String, 'Username of the user', null: true
    field :realname, String, 'Real name of the user', null: true

    def id
      @object.serial_number
    end
  end
end
