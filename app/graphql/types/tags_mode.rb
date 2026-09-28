# frozen_string_literal: true

module Types
  # Whether a photo must carry every listed tag, or just one of them
  class TagsMode < Types::BaseEnum
    description 'Whether tags filters require all tags or any of them'

    value 'ALL', 'Photo must have all of the listed tags', value: 'all'
    value 'ANY', 'Photo must have at least one of the listed tags', value: 'any'
  end
end
