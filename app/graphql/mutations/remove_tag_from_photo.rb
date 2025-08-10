# frozen_string_literal: true

module Mutations
  # Remove Tag from Photo mutation
  class RemoveTagFromPhoto < BaseMutation
    description 'Remove a tag from a photo'

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

      raise GraphQL::ExecutionError, "Tag '#{normalized_tag_name}' is not associated with this photo" unless photo.all_tags_list.include?(normalized_tag_name)

      # TODO: remove machine (rekognition) tags and flickr tags

      photo.tag_list.remove(normalized_tag_name)
      photo.save!

      # Find the tag that was just removed
      tag = ActsAsTaggableOn::Tag.find_by(name: normalized_tag_name)
      raise GraphQL::ExecutionError, "Failed to find tag: #{normalized_tag_name}" if tag.nil?

      { photo: photo, tag: tag }
    end

    private

    def remove_flickr_tag(photo, tag_name)
    end
  end
end
