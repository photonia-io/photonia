# frozen_string_literal: true

module Mutations
  # Update the body of a comment. Author-only.
  class UpdateComment < Mutations::BaseMutation
    description 'Update the body of a comment'

    argument :body, String, 'New body of the comment', required: true
    argument :id, ID, 'Id of the comment', required: true

    type Types::CommentType, null: false

    def resolve(id:, body:)
      comment = Comment.find_by!(serial_number: id)
      authorize(comment, :update?)
      raise GraphQL::ExecutionError, comment.errors.full_messages.join(', ') unless comment.update(body:)

      comment
    end
  end
end
