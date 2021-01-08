# frozen_string_literal: true

require 'image_processing/mini_magick'
require 'exif'

# Our friendly image uploader
class ImageUploader < Shrine
  plugin :model
  plugin :pretty_location
  plugin :determine_mime_type
  plugin :cached_attachment_data
  plugin :store_dimensions, analyzer: :mini_magick
  plugin :add_metadata

  plugin :upload_options, store: lambda { |_io, options|
    if options[:derivative]
      { acl: 'public-read' }
    else
      { acl: 'private' }
    end
  }

  plugin :url_options, store: lambda { |_file, _options|
    {
      public: true,
      host: "https://#{ENV['PHOTONIA_S3_BUCKET']}"
    } if Rails.env.production?
  }

  add_metadata do |io|
    begin
      exif = Exif::Data.new(io)
    rescue Exif::NotReadable # not a valid image
      next { exif: nil }
    end
    { exif: exif }
  end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    {
      extralarge: magick.resize_to_limit!(2048, 2048),
      large: magick.resize_to_limit!(1024, 1024),
      medium: magick.resize_to_limit!(512, 512),
      thumbnail: magick.resize_to_fill!(150, 150)
    }
  end

  def generate_location(_io, record: nil, **context)
    uuid = SecureRandom.uuid
    filename = record_name(record, uuid).gsub(/[Țț]/, 't').gsub(/[Șș]/, 's').parameterize +
               derivative_suffix(context) +
               File.extname(context[:metadata]['filename'])
    record_slug = record.slug.presence || uuid
    "#{record.class.name.downcase}/#{record_slug}/#{filename}"
  end

  def derivative_suffix(context)
    context[:derivative] ? "-#{context[:derivative]}" : '-original'
  end

  def record_name(record, uuid)
    record.name.presence || record.slug.presence || uuid
  end
end
