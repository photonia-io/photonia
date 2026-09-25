# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :text
#  exif                     :jsonb
#  flickr_faves             :integer
#  flickr_impressions_count :integer          default(0), not null
#  flickr_json              :jsonb
#  flickr_original          :string
#  flickr_photopage         :string
#  image_data               :jsonb
#  impressions_count        :integer          default(0), not null
#  labeled_at               :datetime
#  license                  :string
#  posted_at                :datetime
#  privacy                  :enum             default("public")
#  processed_at             :datetime
#  processing_failed_at     :datetime
#  rekognition_response     :jsonb
#  scanned                  :boolean          default(FALSE), not null
#  serial_number            :bigint           not null
#  slug                     :string
#  taken_at                 :datetime
#  taken_at_approximate     :boolean          default(FALSE), not null
#  taken_at_precision       :string           default("minute"), not null
#  taken_at_source          :string           default("unknown"), not null
#  timezone                 :string           default("UTC"), not null
#  title                    :string
#  tsv                      :tsvector
#  user_thumbnail           :jsonb
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
  enum :privacy, {
    public: 'public',
    private: 'private',
    friends_and_family: 'friend & family'
  }, suffix: true

  enum :taken_at_precision, {
    year: 'year',
    month: 'month',
    day: 'day',
    minute: 'minute'
  }, prefix: true

  enum :taken_at_source, {
    exif: 'exif',
    user: 'user',
    unknown: 'unknown'
  }, prefix: true

  MIN_TAKEN_AT_YEAR = 1826

  is_impressionable counter_cache: true, unique: :session_hash

  extend FriendlyId

  friendly_id :serial_number, use: :slugged

  include ImageUploader::Attachment(:image)
  include SerialNumberSetter
  include EXIFUtilities
  include HtmlDescriptionable
  include TrackableTitleAndDescription

  # license is tracked so there's a dated record of every license change
  has_paper_trail only: %i[title description license]

  include PgSearch::Model

  pg_search_scope :search,
                  against: %i[title description],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: 'english',
                      tsvector_column: 'tsv'
                    }
                  }

  acts_as_taggable_on :tags

  default_scope { where(privacy: 'public') }

  # validate that either title or description is present
  validates :title, presence: true, if: -> { description.blank? }
  validates :description, presence: true, if: -> { title.blank? }

  belongs_to :user
  has_many :albums_photos, dependent: :destroy
  has_many :albums, through: :albums_photos
  has_many :comments, -> { order(created_at: :asc) }, as: :commentable, dependent: :destroy
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
      # we can't combine these loops because we need to know the count for each name
      # rubocop:disable Style/CombinableLoops
      proxy_association.target.each do |label|
        label_name = label.name
        if @name_counts[label_name] > 1
          @name_counters[label_name] += 1
          label.sequenced_name = "#{label_name} ##{@name_counters[label_name]}"
        else
          label.sequenced_name = label_name
        end
      end
      # rubocop:enable Style/CombinableLoops
      self
    end
  end

  before_validation :set_fields, prepend: true

  # doesn't work with privacy scopes
  def next
    Photo.where('posted_at > ? OR (posted_at = ? AND id > ?)', posted_at, posted_at, id)
         .order(:posted_at, :id)
         .first
  end

  # doesn't work with privacy scopes
  def prev
    Photo.where('posted_at < ? OR (posted_at = ? AND id < ?)', posted_at, posted_at, id)
         .order(posted_at: :desc, id: :desc)
         .first
  end

  # doesn't work with privacy scopes
  def next_in_album(album)
    AlbumsPhoto.order(:ordering).find_by(
      'ordering > ? AND album_id = ?',
      albums_photos.select { |ap| ap.album_id == album.id }.first.ordering,
      album.id
    )&.photo
  end

  # doesn't work with privacy scopes
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

  def exif_from_file_json
    # we need to clean up the strings in the hash because they might contain
    # invalid UTF-8 characters and those will cause the to_json method to fail
    exif_from_file.to_h.force_encoding_to_iso_8859_1.to_json
  end

  def exif
    unless self[:exif]
      self[:exif] = if exif_from_file
                      exif_from_file_json
                    else
                      { error: 'EXIF Not Readable' }.to_json
                    end
      # if this is a new record, we only want to set the exif field
      # if it's not a new record, we want to save it to cache the exif
      save(validate: false) if persisted?
    end
    JSON.parse(self[:exif])
  end

  def exif_exists?
    # check if exif doesn't contain the error key and only that
    exif.keys != ['error']
  end

  # Refreshes taken_at from EXIF, unless the owner has set it manually.
  # A scanned photo's EXIF date is the digitisation date, not the capture
  # date, so it is never used here.
  def populate_exif_fields
    return self if taken_at_source_user?

    parsed_taken_at = exif_taken_at unless scanned?

    if parsed_taken_at
      self.taken_at_source = 'exif'
      self.taken_at = parsed_taken_at
    else
      self.taken_at_source = 'unknown'
      self.taken_at ||= posted_at || Time.zone.now
    end

    self.taken_at_precision = 'minute'
    self.taken_at_approximate = false

    self
  end

  # year is required; month/day/hour/minute nil means "unknown at this
  # granularity" and derives taken_at_precision. Returns false and populates
  # errors[:taken_at] on invalid input, without touching persisted state.
  def assign_taken_at(year:, month: nil, day: nil, hour: nil, minute: nil, approximate: false, scanned: false)
    error = taken_at_validation_error(year:, month:, day:, hour:, minute:)
    if error
      errors.add(:taken_at, error)
      return false
    end

    date_month = month.presence || 1
    date_day = day.presence || 1

    self.taken_at = ActiveSupport::TimeZone[timezone].local(year, date_month, date_day, hour.presence || 0, minute.presence || 0)
    self.taken_at_precision = taken_at_precision_for(month:, day:, hour:, minute:)
    self.taken_at_source = 'user'
    self.taken_at_approximate = approximate
    self.scanned = scanned

    true
  end

  # Clears the manual date and re-derives taken_at from EXIF (or the upload
  # time). Does not change scanned - resetting the date doesn't un-scan it.
  def reset_taken_at
    self.taken_at_source = 'unknown'
    self.taken_at = nil
    populate_exif_fields
  end

  # Broken out into year/month/day/hour/minute so the client never has to
  # parse a datetime string in a timezone it can't derive.
  def taken_at_info
    return nil unless taken_at

    local = taken_at.in_time_zone(timezone)
    show_month = !taken_at_precision_year?
    show_day = show_month && !taken_at_precision_month?
    show_time = taken_at_precision_minute?

    {
      year: local.year,
      month: show_month ? local.month : nil,
      day: show_day ? local.day : nil,
      hour: show_time ? local.hour : nil,
      minute: show_time ? local.min : nil,
      precision: taken_at_precision,
      source: taken_at_source,
      approximate: taken_at_approximate,
      exif_available: !scanned? && exif_taken_at.present?
    }
  end

  def taken_at_text
    return '' unless taken_at

    local = taken_at.in_time_zone(timezone)

    case taken_at_precision
    when 'year' then local.strftime('%Y')
    when 'month' then local.strftime('%B %Y')
    when 'day' then local.strftime('%B %e, %Y')
    else local.strftime('%B %e, %Y, %H:%M')
    end
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

  # Pixel dimensions of a derivative as actually stored, not the original's -
  # they can disagree when the original carries an EXIF rotation flag, since
  # derivatives are auto-oriented on generation but the original's stored
  # metadata is not. Returns nil if the derivative or its metadata is missing.
  def derivative_dimensions(name)
    metadata = image_data.dig('derivatives', name.to_s, 'metadata')
    return nil unless metadata && metadata['width'] && metadata['height']

    { width: metadata['width'], height: metadata['height'] }
  end

  def add_derivatives
    return unless intelligent_thumbnail.present? || user_thumbnail.present?

    original = image_attacher.file.download

    if intelligent_thumbnail.present?
      pipeline = custom_crop(intelligent_thumbnail, original)
      image_attacher.add_derivative(
        :medium_intelligent,
        pipeline.resize_to_fill!(
          ENV.fetch('MEDIUM_SIDE', nil),
          ENV.fetch('MEDIUM_SIDE', nil)
        )
      )
      image_attacher.add_derivative(
        :thumbnail_intelligent,
        pipeline.resize_to_fill!(
          ENV.fetch('THUMBNAIL_SIDE', nil),
          ENV.fetch('THUMBNAIL_SIDE', nil)
        )
      )
    end

    if user_thumbnail.present?
      pipeline = custom_crop(user_thumbnail, original)
      image_attacher.add_derivative(
        :medium_user,
        pipeline.resize_to_fill!(
          ENV.fetch('MEDIUM_SIDE', nil),
          ENV.fetch('MEDIUM_SIDE', nil)
        )
      )
      image_attacher.add_derivative(
        :thumbnail_user,
        pipeline.resize_to_fill!(
          ENV.fetch('THUMBNAIL_SIDE', nil),
          ENV.fetch('THUMBNAIL_SIDE', nil)
        )
      )
    end

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
    # if(min_distance >= ENV['MEDIUM_SIDE'])
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

  def public?
    privacy == 'public'
  end

  private

  def exif_taken_at
    return nil unless exif_exists?

    # exif_exists? only rules out the {'error' => ...} shape - a real EXIF
    # payload can still be missing the exif/ifd0 sections entirely.
    data = exif
    exif_section = data['exif'].is_a?(Hash) ? data['exif'] : {}
    ifd0_section = data['ifd0'].is_a?(Hash) ? data['ifd0'] : {}
    raw = exif_section['date_time_original'] || ifd0_section['date_time']
    unless raw
      Rails.logger.error "No date taken for #{log_ref}"
      return nil
    end

    Time.use_zone(timezone) { Time.zone.strptime(raw, '%Y:%m:%d %H:%M:%S') }
  rescue ArgumentError
    Rails.logger.error "Invalid date format #{raw} for #{log_ref}"
    nil
  end

  # A new upload has no slug yet, so fall back to the uploaded file's id.
  def log_ref
    slug ? "slug = #{slug}" : "file = #{image_attacher.file&.id}"
  end

  def taken_at_validation_error(year:, month:, day:, hour:, minute:)
    max_year = Date.current.year + 1
    return "year must be between #{MIN_TAKEN_AT_YEAR} and #{max_year}" unless year.is_a?(Integer) && year.between?(MIN_TAKEN_AT_YEAR, max_year)
    return 'day cannot be set without month' if day.present? && month.blank?
    return 'time of day requires a full date' if (hour.present? || minute.present?) && (month.blank? || day.blank?)
    return 'is not a valid date' unless Date.valid_date?(year, month.presence || 1, day.presence || 1)
    return 'hour must be between 0 and 23' if hour.present? && !hour.between?(0, 23)
    return 'minute must be between 0 and 59' if minute.present? && !minute.between?(0, 59)

    nil
  end

  def taken_at_precision_for(month:, day:, hour:, minute:)
    return 'year' if month.blank?
    return 'month' if day.blank?
    return 'day' if hour.blank? && minute.blank?

    'minute'
  end

  def custom_crop(thumbnail, original = nil)
    original ||= image_attacher.file.download

    # Compute pixel coordinates from axis-relative percentages
    # Handle both symbol and string keys (user_thumbnail uses strings from JSONB, intelligent_thumbnail uses symbols)
    top = thumbnail[:top] || thumbnail['top']
    left = thumbnail[:left] || thumbnail['left']
    width_percent = thumbnail[:width] || thumbnail['width']
    height_percent = thumbnail[:height] || thumbnail['height']

    x = (pixel_width * left).to_i
    y = (pixel_height * top).to_i
    width_px = (pixel_width * width_percent).to_i
    height_px = (pixel_height * height_percent).to_i

    # Use the smaller dimension to ensure the crop is square
    square_size = [width_px, height_px].min

    ImageProcessing::MiniMagick
      .source(original)
      .crop(x, y, square_size, square_size)
  end

  def set_fields
    set_serial_number
    self.posted_at = Time.current if posted_at.nil?
  end
end
