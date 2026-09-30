# frozen_string_literal: true

module Types
  # Public-facing author of a comment. Deliberately not UserType, which
  # exposes email and other private fields.
  class CommentAuthorType < Types::BaseObject
    description 'The site user who posted a comment'

    field :display_name, String, 'Public display name', null: false
    field :id, String, 'ID of the user', null: false

    def id
      @object.slug
    end

    def display_name
      @object.public_name
    end
  end
end
