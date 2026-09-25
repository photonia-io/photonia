# frozen_string_literal: true

module Mutations
  # Base mutation
  class BaseMutation < GraphQL::Schema::Mutation
    null false

    private

    def authorize(record, action)
      context[:authorize].call(record, action)
    end

    # Both models default-scope to public records, so a plain friendly.find
    # can't see the current user's own private/friends-only records.
    def find_photo(id)
      Pundit.policy_scope(context[:current_user], Photo.unscoped).friendly.find(id)
    end

    def find_album(id)
      Pundit.policy_scope(context[:current_user], Album.unscoped).friendly.find(id)
    end

    def handle_photo_update_errors(photo)
      if photo.errors[:title].include?("can't be blank") && photo.errors[:description].include?("can't be blank")
        raise GraphQL::ExecutionError, 'Either title or description is required'
      end

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ')
    end
  end
end
