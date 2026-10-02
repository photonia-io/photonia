# frozen_string_literal: true

module Types
  # A photo with its view count on a given day
  class ViewedPhotoType < Types::BaseObject
    description 'A photo and how many times it was viewed'

    field :count, Integer, 'Number of views', null: false
    field :photo, PhotoType, 'The viewed photo', null: false
  end
end
