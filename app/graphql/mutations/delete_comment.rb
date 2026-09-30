# frozen_string_literal: true

module Mutations
  # Delete a comment. Its author, the commentable's owner, or an admin may
  # delete it; deleting a top-level comment deletes its replies too.
  class DeleteComment < Mutations::BaseMutation
    description 'Delete a comment'

    argument :id, ID, 'Id of the comment', required: true

    type Types::CommentType, null: false

    def resolve(id:)
      comment = Comment.find_by!(serial_number: id)
      authorize(comment, :destroy?)
      comment.destroy!
      comment
    end
  end
end
