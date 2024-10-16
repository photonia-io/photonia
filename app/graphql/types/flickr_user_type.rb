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

    def id
      @object.serial_number
    end
  end
end
