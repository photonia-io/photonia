# frozen_string_literal: true

module Types
  # GraphQL Comment Type
  class CommentType < Types::BaseObject
    description 'A Comment'

    field :body, String, 'Body of the comment', null: false
    field :body_html, String, 'Body of the comment in HTML', null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, 'Creation datetime of the comment', null: false
    field :flickr_link, String, 'Flickr link', null: true
    field :flickr_user, FlickrUserType, 'Flickr user who posted the comment', null: true
    field :id, ID, 'ID of the comment', null: false
    # field :user, UserType, 'User who posted the comment', null: true

    def id
      @object.serial_number
    end
  end
end
