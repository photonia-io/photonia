# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                       :bigint           not null, primary key
#  date_taken               :datetime
#  description              :text
#  exif                     :jsonb
#  flickr_faves             :integer
#  flickr_impressions_count :integer          default(0), not null
#  flickr_json              :jsonb
#  flickr_original          :string
#  flickr_photopage         :string
#  image_data               :jsonb
#  imported_at              :datetime
#  impressions_count        :integer          default(0), not null
#  license                  :string
#  name                     :string
#  privacy                  :enum             default("public")
#  rekognition_response     :jsonb
#  serial_number            :bigint           not null
#  slug                     :string
#  timezone                 :string           default("UTC"), not null
#  tsv                      :tsvector
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint
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
  is_impressionable counter_cache: true, unique: :session_hash

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

  # validate name and description
  validates :name, presence: true
  validates :description, presence: true

  belongs_to :user
  has_many :albums_photos, dependent: :destroy
  has_many :albums, through: :albums_photos
  has_many :labels, dependent: :destroy do
    def center_of_gravity
      Photo::Point.new(average(:top), average(:left))
    end

    # type is usually :top or :left
    def average(type)
      total = 0
      area_total = 0
      filtered.each do |label|
        total += label.center.send(type) * label.area
        area_total += label.area
      end
      if area_total.zero?
        0.5
      else
        total / area_total
      end
    end

    def filtered
      person_present? ? proxy_association.target.select(&:person?) : proxy_association.target
    end

    def person_present?
      proxy_association.target.any?(&:person?)
    end

    def add_sequenced_names
      @name_counts = Hash.new(0)
      @name_counters = Hash.new(0)
      proxy_association.target.each { |label| @name_counts[label.name] += 1 }
      proxy_association.target.each do |label|
        label_name = label.name
        if @name_counts[label_name] > 1
          @name_counters[label_name] += 1
          label.sequenced_name = "#{label_name} ##{@name_counters[label_name]}"
        else
          label.sequenced_name = label_name
        end
      end
      self
    end
  end

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

  def exif_from_file
    @exif_from_file ||= begin
      file = image_attacher.file
      file.open do
        Rails.logger.info "Downloaded file: #{file.id}"
        Exif::Data.new(file.tempfile)
      rescue Exif::NotReadable
        Rails.logger.error "EXIF Not Readable: #{file.id}"
        nil
      end
    end
  end

  def exif
    # calling this the first time will call exif_from_file and save the result into the field
    unless self[:exif]
      if exif_from_file
        # we need to clean up the strings in the hash because they might contain
        # invalid UTF-8 characters and those will cause the to_json method to fail
        self[:exif] = exif_from_file.to_h.force_encoding_to_iso_8859_1.to_json
      else
        self[:exif] = { error: 'EXIF Not Readable' }.to_json
      end
      save
    end
    # byebug
    JSON.parse(self[:exif])
  end

  def exif_exists?
    # check if exif doesn't contain the error key and only that
    exif.keys != ['error']
  end

  def populate_exif_fields
    if exif_exists?
      exif_date_taken = exif['exif']['date_time_original']
      exif_date_format = '%Y:%m:%d %H:%M:%S'
      Time.zone = timezone
      self.date_taken = Time.zone.strptime(exif_date_taken, exif_date_format)
    else
      self.date_taken = Time.current
    end
    self
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

    if labels.blank?
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
    return unless labels.present? && ratio > 1.02

    cog = labels.center_of_gravity
    cog_left = cog.left
    cog_top = cog.top
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
