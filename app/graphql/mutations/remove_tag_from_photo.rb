# frozen_string_literal: true

module Mutations
  # Remove Tag from Photo mutation
  class RemoveTagFromPhoto < BaseMutation
    description 'Remove a tag from a photo'

    argument :id, ID, 'Photo Id', required: true
    argument :tag_name, String, 'Tag name', required: true

    field :photo, Types::PhotoType, null: false, description: 'The photo from which the tag was removed'

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

      TaggingSource.find_each do |tagging_source|
        source_tags = photo.tags_from(tagging_source)
        next unless source_tags.include?(normalized_tag_name)

        updated_source_tags = source_tags - [normalized_tag_name]
        tagging_source.tag(photo, with: updated_source_tags, on: :tags)
      end

      photo.tag_list.remove(normalized_tag_name) if photo.tag_list.include?(normalized_tag_name)

      photo.save!

      { photo: photo }
    end
  end
end
