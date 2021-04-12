# frozen_string_literal: true

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
    Photo.where('date_taken > ?', date_taken).order(:date_taken).first
  end

  def prev
    Photo.where('date_taken < ?', date_taken).order(date_taken: :desc).first
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

  def populate_exif_fields
    if (exif = image.metadata['exif'])
      self.date_taken = DateTime.strptime(exif.date_time_original, '%Y:%m:%d %H:%M:%S') if exif.date_time_original
      Hash.include CoreExtensions::Hash::Sanitizer
      image.metadata['exif'] = image.metadata['exif'].to_h.sanitize_invalid_byte_sequence!
    end

    self.date_taken ||= Time.current # if date taken was not found in EXIF default to current timestamp

    self
  end

  def label_instances
    label_instances = []
    rekognition_response['labels'].each do |label|
      next unless (instances = label['instances'].presence)

      instances.each do |instance|
        label_instances << {
          'name' => label['name'],
          'bounding_box' => instance['bounding_box']
        }
      end
    end
    label_instances
  end

  def main_instance_center
    bounding_box = label_instances.first['bounding_box']
    {
      top: bounding_box['top'] + bounding_box['height'] / 2,
      left: bounding_box['left'] + bounding_box['width'] / 2
    }
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
