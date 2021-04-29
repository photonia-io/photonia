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

  def populate_exif_fields
    if (exif = image.metadata['exif'])
      self.date_taken = DateTime.strptime(exif.date_time_original, '%Y:%m:%d %H:%M:%S') if exif.date_time_original
      Hash.include CoreExtensions::Hash::Sanitizer
      image.metadata['exif'] = image.metadata['exif'].to_h.sanitize_invalid_byte_sequence!
    end

    self.date_taken ||= Time.current # if date taken was not found in EXIF default to current timestamp

    self
  end

  def label_instance_collection
    lic = LabelInstanceCollection.new
    rekognition_response['labels'].each do |label|
      next unless (instances = label['instances'].presence)

      lic.add(label, instances)
    end
    lic
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
