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

  desc 'Run maintenance on all albums'
  task maintenance: :environment do
    Album.unscoped.find_each do |album|
      album.maintenance
    end
  end

  desc 'Set HTML description for all albums'
  task set_description_html: :environment do
    Album.unscoped.find_each do |album|
      album.send(:set_description_html)
      album.save(validate: false)
    end
  end

  desc 'Resync serial numbers from slugs'
  task resync_serial_numbers: :environment do
    Album.update_all('serial_number = slug::bigint')
  end
end
