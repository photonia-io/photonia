# frozen_string_literal: true

module Types
  # The most viewed photos and albums on a day
  class MostViewedOnDateType < Types::BaseObject
    description 'Most viewed photos and albums on a date'

    field :albums, [ViewedAlbumType], 'Most viewed albums', null: false
    field :photos, [ViewedPhotoType], 'Most viewed photos', null: false
  end
end
