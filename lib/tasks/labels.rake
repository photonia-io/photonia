# frozen_string_literal: true

namespace :labels do
  desc 'Resets label table'
  task reset: :environment do
    ActiveRecord::Base.connection.execute(
      <<~SQL.squish
        TRUNCATE TABLE labels RESTART IDENTITY CASCADE;
      SQL
    )
  end

  desc 'Extracts labels from photos'
  task add_labels_from_rekognition_response: :environment do
    # get all photos where rekognition_response is not null
    Photo.unscoped.where.not(rekognition_response: nil).each do |photo|
      PhotoLabeler.new(photo).add_labels_from_rekognition_response
    end
  end
end
