# frozen_string_literal: true

module Mutations
  # Delete an album share/invite (revoke access)
  class DeleteAlbumShare < Mutations::BaseMutation
    description 'Revoke album access by deleting a share'

    argument :id, ID, 'Album share ID', required: true

    field :success, Boolean, 'Whether the share was deleted successfully', null: false

    def resolve(id:)
      share = AlbumShare.find_by(id:)
      raise GraphQL::ExecutionError, 'Share not found' unless share

      # Only the album owner can delete shares
      authorize(share.album, :update?)

      share.destroy!
      { success: true }
    end
  end
end
