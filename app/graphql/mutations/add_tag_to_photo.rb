# frozen_string_literal: true

module Mutations
  # Add Tag to Photo mutation
  class AddTagToPhoto < BaseMutation
    description 'Add a tag to a photo'

    argument :id, String, 'Photo Id', required: true
    argument :tag_name, String, 'Tag name', required: true

    field :photo, Types::PhotoType, null: false
    field :tag, Types::TagType, null: false

    def resolve(id:, tag_name:)
      begin
        photo = Photo.friendly.find(id)
      rescue ActiveRecord::RecordNotFound
        raise GraphQL::ExecutionError, 'Photo not found'
      end

      normalized_tag_name = TagNormalizer.normalize(tag_name)
      raise GraphQL::ExecutionError, 'Tag name cannot be empty' if normalized_tag_name.empty?

      authorize(photo, :update?)

      unless photo.all_tags_list.include?(normalized_tag_name)
        photo.tag_list.add(normalized_tag_name)
        photo.save!
      end

      # Find the tag that was just added
      tag = ActsAsTaggableOn::Tag.find_by(name: normalized_tag_name)
      raise GraphQL::ExecutionError, "Failed to find or create tag: #{normalized_tag_name}" if tag.nil?

      { photo: photo, tag: tag }
    end
  end
end
