# frozen_string_literal: true

module Types
  # A camera make/model, with a count of matching photos (advanced search
  # form option list)
  class CameraType < Types::BaseObject
    description 'A camera make/model with a photo count'

    field :count, Integer, 'Number of photos with this camera', null: false
    field :friendly_name, String, 'Human-friendly camera name', null: false
    field :make, String, 'EXIF camera make', null: false
    field :model, String, 'EXIF camera model', null: false
  end
end
