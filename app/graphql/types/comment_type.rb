# frozen_string_literal: true

module Types
  # GraphQL Comment Type
  class CommentType < Types::BaseObject
    description 'A Comment'

    field :body, String, 'Body of the comment', null: false
    field :body_edited, Boolean, 'Whether the body of the comment has been edited', null: false
    field :body_html, String, 'Body of the comment in HTML', null: true
    field :body_last_edited_at, GraphQL::Types::ISO8601DateTime, 'Datetime when the body was last edited', null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, 'Creation datetime of the comment', null: false
    field :flickr_link, String, 'Flickr link', null: true
    field :flickr_user, FlickrUserType, 'Flickr user who posted the comment', null: true
    field :id, ID, 'ID of the comment', null: false
    # field :user, UserType, 'User who posted the comment', null: true

    def body_edited
      @object.body_edited?
    end

    def id
      @object.serial_number
    end
  end
end
