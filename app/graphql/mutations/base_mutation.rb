# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    null false

    private

    def handle_photo_update_errors(photo)
      if photo.errors[:title].include?("can't be blank") && photo.errors[:description].include?("can't be blank")
        raise GraphQL::ExecutionError, 'Either title or description is required'
      else
        raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ')
      end
    end
  end
end
