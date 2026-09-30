# frozen_string_literal: true

module Mutations
  # Create a comment on a photo or an album, optionally as a reply to an
  # existing top-level comment (one level of threading only).
  class CreateComment < Mutations::BaseMutation
    description 'Create a comment on a photo or an album'

    COMMENTABLE_TYPES = %w[Photo Album].freeze

    argument :body, String, 'Body of the comment', required: true
    argument :commentable_id, String, 'Id (slug) of the photo or album being commented on', required: true
    argument :commentable_type, String, 'Type of the commentable ("Photo" or "Album")', required: true
    argument :parent_id, ID, 'Id of the top-level comment being replied to', required: false

    type Types::CommentType, null: false

    def resolve(commentable_type:, commentable_id:, body:, parent_id: nil)
      raise GraphQL::ExecutionError, 'Invalid commentable type' unless COMMENTABLE_TYPES.include?(commentable_type)
      raise GraphQL::ExecutionError, 'Commenting is disabled' unless commenting_allowed?(commentable_type)

      commentable = find_commentable(commentable_type, commentable_id)
      parent = find_parent(commentable, parent_id)

      comment = commentable.comments.build(body:, user: context[:current_user], parent:)
      authorize(comment, :create?)
      raise GraphQL::ExecutionError, comment.errors.full_messages.join(', ') unless comment.save

      notify_owner(comment, commentable)
      comment
    end

    private

    def commenting_allowed?(commentable_type)
      return false unless Setting.commenting_enabled

      commentable_type == 'Photo' ? Setting.photo_commenting_enabled : Setting.album_commenting_enabled
    end

    def find_commentable(commentable_type, commentable_id)
      commentable_type == 'Photo' ? find_photo(commentable_id) : find_album(commentable_id)
    end

    # Scoped to this commentable's top-level comments, so a reply-to-a-reply
    # or a parent belonging to a different photo/album is a plain not-found.
    def find_parent(commentable, parent_id)
      return nil unless parent_id

      commentable.comments.top_level.find_by!(serial_number: parent_id)
    end

    def notify_owner(comment, commentable)
      return if comment.user_id == commentable.user_id

      UserMailer.with(comment:).new_comment.deliver_later
    end
  end
end
