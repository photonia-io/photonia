# frozen_string_literal: true

namespace :albums do
  desc 'Resets album tables'
  task reset: :environment do
    ActiveRecord::Base.connection.execute(
      <<~SQL.squish
        TRUNCATE TABLE albums_photos RESTART IDENTITY CASCADE;
        TRUNCATE TABLE albums RESTART IDENTITY CASCADE;
      SQL
    )
  end

  desc 'Copy flickr_views to impressions_count'
  task copy_flickr_views_to_impressions_count: :environment do
    Album.all.each do |album|
      album.update(impressions_count: album.flickr_views)
    end
  end
end
