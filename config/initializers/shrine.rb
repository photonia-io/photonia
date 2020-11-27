# frozen_string_literal: true

require 'shrine'

if Rails.env.test?
  require 'shrine/storage/memory'

  Shrine.storages = {
    store: Shrine::Storage::Memory.new
  }
else
  require 'shrine/storage/s3'

  s3_options = {
    access_key_id: ENV['PHOTONIA_S3_ACCESS_KEY_ID'],
    secret_access_key: ENV['PHOTONIA_S3_SECRET_ACCESS_KEY'],
    region: ENV['PHOTONIA_S3_REGION'],
    bucket: ENV['PHOTONIA_S3_BUCKET']
  }

  Shrine.storages = {
    store: Shrine::Storage::S3.new(**s3_options)
  }
end

Shrine.plugin :activerecord
Shrine.plugin :derivatives
