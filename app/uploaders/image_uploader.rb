# frozen_string_literal: true

require 'image_processing/vips'
require 'exif'

# Our friendly image uploader
class ImageUploader < Shrine
  plugin :model
  plugin :pretty_location
  plugin :determine_mime_type
  plugin :cached_attachment_data
  plugin :store_dimensions, analyzer: :ruby_vips
  plugin :tempfile

  # JPEG quality per derivative size; EXIF is stripped (the private original keeps it)
  QUALITY = { extralarge: 90, large: 90, medium: 85, thumbnail: 80 }.freeze
  # libvips < 8.15 can't keep just the colour profile, so it strips everything
  METADATA = Vips.at_least_libvips?(8, 15) ? { keep: 'icc' } : { strip: true }

  def self.saver_options(size)
    { quality: QUALITY.fetch(size), **METADATA }
  end

  plugin :upload_options, store: lambda { |_io, options|
    if options[:derivative]
      { acl: 'public-read' }
    else
      { acl: 'private' }
    end
  }

  plugin :url_options, store: lambda { |_file, _options|
    if Rails.env.production?
      {
        public: true,
        host: "https://#{ENV.fetch('S3_BUCKET', nil)}"
      }
    end
  }

  Attacher.derivatives do |original|
    vips = ImageProcessing::Vips.source(original)
    {
      extralarge: vips.saver(**ImageUploader.saver_options(:extralarge)).resize_to_limit!(2048, 2048),
      large: vips.saver(**ImageUploader.saver_options(:large)).resize_to_limit!(1024, 1024),
      medium: vips.saver(**ImageUploader.saver_options(:medium)).resize_to_limit!(
        ENV.fetch('MEDIUM_SIDE', nil).to_i,
        ENV.fetch('MEDIUM_SIDE', nil).to_i
      ),
      medium_square: vips.saver(**ImageUploader.saver_options(:medium)).resize_to_fill!(
        ENV.fetch('MEDIUM_SIDE', nil).to_i,
        ENV.fetch('MEDIUM_SIDE', nil).to_i
      ),
      thumbnail_square: vips.saver(**ImageUploader.saver_options(:thumbnail)).resize_to_fill!(
        ENV.fetch('THUMBNAIL_SIDE', nil).to_i,
        ENV.fetch('THUMBNAIL_SIDE', nil).to_i
      )
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
    record.title.presence || record.slug.presence || uuid
  end
end
