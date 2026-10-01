# frozen_string_literal: true

module Types
  # Public archive totals for the homepage stats line and year links
  class HomepageStatsType < Types::BaseObject
    description 'Totals over the publicly visible archive'

    # Photos grouped by the year of taken_at
    class YearCountType < Types::BaseObject
      field :count, Integer, 'Number of photos taken that year', null: false
      field :year, Integer, 'Year', null: false
    end

    field :albums_count, Integer, 'Number of public albums with public photos', null: false
    field :first_year, Integer, 'Earliest year photos were taken', null: true
    field :last_year, Integer, 'Latest year photos were taken', null: true
    field :photos_count, Integer, 'Number of public photos', null: false
    field :views_count, Integer, 'Total views, including those on Flickr', null: false
    field :years, [YearCountType], 'Photo counts per year, newest year first', null: false
  end
end
