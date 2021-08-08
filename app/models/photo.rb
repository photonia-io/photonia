# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                   :bigint           not null, primary key
#  date_taken           :datetime
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
# Photo model, uuuh :)
class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include ImageUploader::Attachment(:image)

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

  def exif
    image.metadata['exif']
  end

  def sanitize_exif
    return unless exif

    Hash.include CoreExtensions::Hash::Sanitizer
    image.metadata['exif'] = exif.to_h.sanitize_invalid_byte_sequence!
  end

  def populate_exif_fields
    self.date_taken = DateTime.strptime(exif.date_time_original, '%Y:%m:%d %H:%M:%S') if exif&.date_time_original
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

  def thumbnail
    cog = label_instance_collection.center_of_gravity
    cog_left = cog[:left]
    cog_top = cog[:top]
    pixel_width = image.metadata['width']
    pixel_height = image.metadata['height']
    cog_x = (pixel_width * cog_left).to_i
    cog_y = (pixel_height * cog_top).to_i
    distances = {
      n: cog_y,
      w: pixel_width - cog_x,
      s: pixel_height - cog_y,
      e: cog_x
    }
    closest_pole, min_distance = distances.min_by { |_, distance| distance }
    # if(min_distance >= ENV['PHOTONIA_MEDIUM_SIDE'])
      {
        x: x = cog_x - min_distance,
        y: y = cog_y - min_distance,
        pixel_width: min_distance * 2,
        pixel_height: min_distance * 2,
        top: y.to_f / pixel_height,
        left: x.to_f / pixel_width,
        width: min_distance.to_f * 2 / pixel_width,
        height: min_distance.to_f * 2 / pixel_height
      }
    # end
  end

  def intelligent_medium
    attacher = photo.image_attacher

    return unless attacher.derivatives.key?(:medium)

    old_medium = attacher.derivatives[:medium]
    intelligent_medium = attacher.file.download do |original|
      ImageProcessing::MiniMagick
        .source(original)
        .resize_to_limit!(600, 600)
    end

    attacher.add_derivative(:medium, intelligent_medium)

    begin
      attacher.atomic_persist               # persist changes if attachment has not changed in the meantime
      old_medium.delete                     # delete old derivative
    rescue Shrine::AttachmentChanged,       # attachment has changed
           ActiveRecord::RecordNotFound     # record has been deleted
      attacher.derivatives[:medium].delete  # delete now orphaned derivative
    end
  end

  private

  def set_fields
    if serial_number.nil?
      maximum_serial_number = Photo.unscoped.maximum('serial_number') || 1_000_000_000
      self.serial_number = maximum_serial_number + rand(1..10_000_000)
    end

    self.imported_at = Time.current if imported_at.nil?
  end
end
