# frozen_string_literal: true

module Types
  # A distinct Rekognition label name, with a count of matching photos
  # (advanced search's label autocomplete)
  class LabelNameType < Types::BaseObject
    description 'A label name with a photo count'

    field :count, Integer, 'Number of photos with this label', null: false
    field :name, String, 'Label name', null: false
  end
end
