# frozen_string_literal: true

require 'image_processing/mini_magick'

# Our friendly image uploader
class ImageUploader < Shrine
  plugin :pretty_location
  plugin :determine_mime_type
  plugin :cached_attachment_data
  plugin :store_dimensions, analyzer: :mini_magick

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
      host: 'https://' + ENV['PHOTONIA_S3_BUCKET']
    } if Rails.env.production?
  }

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    {
      extralarge: magick.resize_to_limit!(2048, 2048),
      large: magick.resize_to_limit!(1024, 1024),
      medium: magick.resize_to_limit!(512, 512),
      thumbnail: magick.resize_to_fill!(150, 150)
    }
  end

  def generate_location(io, record: nil, **context)
    derivative = context[:derivative] ? "-#{context[:derivative]}" : '-original'
    filename = record.name.gsub(/[Țț]/, 't').gsub(/[Șș]/, 's').parameterize +
               derivative +
               File.extname(context[:metadata]['filename'])
    "#{record.class.name.downcase}/#{record.slug}/#{filename}"
  end
end
