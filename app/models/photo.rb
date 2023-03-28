# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                   :bigint           not null, primary key
#  date_taken           :datetime
#  derivatives_version  :string           default("original")
#  description          :text
#  exif                 :jsonb
#  flickr_faves         :integer
#  flickr_json          :jsonb
#  flickr_original      :string
#  flickr_photopage     :string
#  flickr_views         :integer
#  image_data           :jsonb
#  imported_at          :datetime
#  license              :string
#  name                 :string
#  privacy              :enum             default("public")
#  rekognition_response :jsonb
#  serial_number        :bigint           not null
#  slug                 :string
#  tsv                  :tsvector
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  user_id              :bigint
#
# Indexes
#
#  index_photos_on_exif                  (exif) USING gin
#  index_photos_on_rekognition_response  (rekognition_response) USING gin
#  index_photos_on_slug                  (slug) UNIQUE
#  index_photos_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include ImageUploader::Attachment(:image)
  include SerialNumberSetter

  include PgSearch::Model
  pg_search_scope :search,
                  against: %i[name description],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: 'english',
                      tsvector_column: 'tsv'
                    }
                  }

  acts_as_taggable_on :tags

  default_scope { where(privacy: 'public') }

  belongs_to :user
  has_many :albums_photos, dependent: :destroy
  has_many :albums, through: :albums_photos

  before_validation :set_fields, prepend: true

  def next
    Photo.where('imported_at > ?', imported_at).order(:imported_at).first
  end

  def prev
    Photo.where('imported_at < ?', imported_at).order(imported_at: :desc).first
  end

  def next_in_album(album)
    AlbumsPhoto.order(:ordering).find_by(
      'ordering > ? AND album_id = ?',
      albums_photos.select { |ap| ap.album_id == album.id }.first.ordering,
      album.id
    )&.photo
  end

  def prev_in_album(album)
    AlbumsPhoto.order(ordering: :desc).find_by(
      'ordering < ? AND album_id = ?',
      albums_photos.select { |ap| ap.album_id == album.id }.first.ordering,
      album.id
    )&.photo
  end

  def exif(file)
    Exif::Data.new(file.tempfile)
  end

  def populate_exif_fields
    file = image_attacher.file
    file.open do
      if exif(file)&.date_time_original
        self.date_taken = DateTime.strptime(exif(file).date_time_original, '%Y:%m:%d %H:%M:%S')
      end
    end
    self.date_taken ||= Time.current # if date taken was not found in EXIF default to current timestamp
    self
  end

  def label_instance_collection
    return unless rekognition_response

    lic = Label::Instance::Collection.new
    rekognition_response['labels'].each do |label|
      next unless (instances = label['instances'].presence)

      lic.add(label, instances)
    end

    lic
  end

  def label_instances
    label_instance_collection&.label_instances
  end

  def pixel_width
    image.metadata['width']
  end

  def pixel_height
    image.metadata['height']
  end

  def ratio
    pixel_width > pixel_height ? pixel_width.to_f / pixel_height : pixel_height.to_f / pixel_width
  end

  def add_intelligent_derivatives
    # Log Intelligent Derivatives Attempt

    if label_instances.blank?
      # Log Error: No Label Instances
      return
    end

    unless intelligent_thumbnail
      # Log Error: No Thumbnail (Probably square)
      return
    end

    image_attacher.add_derivative(
      :medium_intelligent,
      intelligent_crop.resize_to_fill!(
        ENV.fetch('PHOTONIA_MEDIUM_SIDE', nil),
        ENV.fetch('PHOTONIA_MEDIUM_SIDE', nil)
      )
    )

    image_attacher.add_derivative(
      :thumbnail_intelligent,
      intelligent_crop.resize_to_fill!(
        ENV.fetch('PHOTONIA_THUMBNAIL_SIDE', nil),
        ENV.fetch('PHOTONIA_THUMBNAIL_SIDE', nil)
      )
    )

    image_attacher.atomic_promote
  end

  def intelligent_thumbnail
    return unless label_instances.present? && ratio > 1.02

    cog = label_instance_collection.center_of_gravity
    cog_left = cog[:left]
    cog_top = cog[:top]
    cog_x = (pixel_width * cog_left).to_i
    cog_y = (pixel_height * cog_top).to_i
    distances = {
      n: cog_y,
      w: pixel_width - cog_x,
      s: pixel_height - cog_y,
      e: cog_x
    }
    # closest_pole, min_distance = distances.min_by { |_, distance| distance }
    _, min_distance = distances.min_by { |_, distance| distance }
    # if(min_distance >= ENV['PHOTONIA_MEDIUM_SIDE'])
    {
      x: x = cog_x - min_distance,
      y: y = cog_y - min_distance,
      pixel_width: min_distance * 2,
      pixel_height: min_distance * 2,
      top: y.to_f / pixel_height,
      left: x.to_f / pixel_width,
      width: min_distance.to_f * 2 / pixel_width,
      height: min_distance.to_f * 2 / pixel_height,
      center_of_gravity_left: cog_left,
      center_of_gravity_top: cog_top
    }
    # end
  end

  private

  def intelligent_crop
    original = image_attacher.file.download
    ImageProcessing::MiniMagick
      .source(original)
      .crop(
        intelligent_thumbnail[:x],
        intelligent_thumbnail[:y],
        intelligent_thumbnail[:pixel_width],
        intelligent_thumbnail[:pixel_height]
      )
  end

  def set_fields
    set_serial_number
    self.imported_at = Time.current if imported_at.nil?
  end
end
