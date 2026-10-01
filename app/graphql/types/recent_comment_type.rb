# frozen_string_literal: true

module Types
  # A comment on a public photo or album, with enough context to link to it
  # from the homepage
  class RecentCommentType < Types::BaseObject
    description 'A recent comment together with the photo or album it is on'

    field :album, AlbumType, 'The album commented on, if it is an album', null: true
    field :author_name, String, 'Public name of the commenter', null: false
    field :comments_count, Integer, 'Total comments on the photo or album', null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, 'When the comment was posted', null: false
    field :id, ID, 'ID of the comment', null: false
    field :photo, PhotoType, 'The photo commented on, if it is a photo', null: true
    field :snippet, String, 'Plain-text excerpt of the comment', null: false
  end
end
