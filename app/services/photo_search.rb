# frozen_string_literal: true

# Composes advanced-search filters onto a photo relation (#1101). Every
# relational filter is an EXISTS / id IN (subquery) / NOT EXISTS/IN, never a
# join + distinct: pg_search's #search orders by a rank column outside the
# select list, and SELECT DISTINCT with such an ORDER BY errors.
#
# Callers pass an already Pundit-scoped relation (e.g.
# Pundit.policy_scope(current_user, Photo.unscoped)) and an album_scope
# (likewise Pundit-scoped) used to resolve the album filter.
class PhotoSearch
  CAMERA_MAKE_PATH = %w[ifd0 make].freeze
  CAMERA_MODEL_PATH = %w[ifd0 model].freeze
  ISO_PATH = %w[exif iso_speed_ratings].freeze
  F_NUMBER_PATH = %w[exif fnumber].freeze
  FOCAL_LENGTH_PATH = %w[exif focal_length].freeze

  # PhotoSortField values that map straight to a photos column.
  SORT_COLUMNS = {
    'taken_at' => 'taken_at',
    'posted_at' => 'posted_at',
    'flickr_faves' => 'flickr_faves'
  }.freeze

  DIRECTIONS = %w[asc desc].freeze

  def initialize(relation, filters, sort: 'relevance', direction: 'desc', album_scope: Album.none)
    @relation = relation
    @filters = filters.symbolize_keys
    @sort = sort.to_s
    @direction = DIRECTIONS.include?(direction.to_s) ? direction.to_s : 'desc'
    @album_scope = album_scope
  end

  def relation
    apply_filters
    apply_sort
    @relation
  end

  private

  attr_reader :filters

  def apply_filters
    apply_text_search
    apply_tags
    apply_dates
    apply_camera
    apply_numeric_exif
    apply_labels
    apply_license
    apply_album
    apply_privacy
    apply_missing_data
  end

  def apply_text_search
    return if filters[:query].blank?

    @relation = @relation.search(filters[:query])
  end

  def apply_tags
    names = normalized_names(filters[:tags])
    if names.any?
      @relation =
        if filters[:tags_mode] == 'all'
          # One any:-scoped call per tag, chained, rather than
          # acts-as-taggable-on's ALL builder: that joins one taggings alias
          # per tag and duplicates a photo carrying the same tag from two
          # taggers (e.g. Flickr + Rekognition).
          names.reduce(@relation) { |relation, name| relation.tagged_with(name, any: true) }
        else
          @relation.tagged_with(names, any: true)
        end
    end

    exclude_names = normalized_names(filters[:exclude_tags])
    @relation = @relation.tagged_with(exclude_names, exclude: true) if exclude_names.any?
  end

  def normalized_names(names)
    Array(names).map { |name| TagNormalizer.normalize(name) }.reject(&:blank?)
  end

  def apply_dates
    if filters[:taken_at_from].present? || filters[:taken_at_to].present?
      @relation = @relation.where(taken_at: date_range(filters[:taken_at_from], filters[:taken_at_to]))
    end

    return unless filters[:posted_at_from].present? || filters[:posted_at_to].present?

    @relation = @relation.where(posted_at: date_range(filters[:posted_at_from], filters[:posted_at_to]))
  end

  def date_range(from, to)
    from_time = from&.in_time_zone('UTC')&.beginning_of_day
    to_time = to&.in_time_zone('UTC')&.end_of_day
    from_time..to_time
  end

  def apply_camera
    if filters[:camera_make].present?
      @relation = @relation.where("exif #>> '{#{CAMERA_MAKE_PATH.join(',')}}' = ?", filters[:camera_make])
    end

    return if filters[:camera_model].blank?

    @relation = @relation.where("exif #>> '{#{CAMERA_MODEL_PATH.join(',')}}' = ?", filters[:camera_model])
  end

  def apply_numeric_exif
    apply_numeric_range(ISO_PATH, filters[:iso_min], filters[:iso_max])
    apply_numeric_range(F_NUMBER_PATH, filters[:f_number_min], filters[:f_number_max])
    apply_numeric_range(FOCAL_LENGTH_PATH, filters[:focal_length_min], filters[:focal_length_max])
  end

  def apply_numeric_range(path, min, max)
    return if min.nil? && max.nil?

    sql = numeric_exif_sql(path)
    @relation = @relation.where("#{sql} >= ?", min) unless min.nil?
    @relation = @relation.where("#{sql} <= ?", max) unless max.nil?
  end

  # The exif gem serializes rationals (fnumber, focal_length) as "a/b"
  # strings, while iso_speed_ratings is a plain number. This handles both
  # shapes; path is one of the *_PATH constants above, never user input.
  def numeric_exif_sql(path)
    raw = "(exif #>> '{#{path.join(',')}}')"
    'CASE ' \
      "WHEN #{raw} ~ '^[0-9]+/[0-9]+$' " \
      "THEN split_part(#{raw}, '/', 1)::numeric / NULLIF(split_part(#{raw}, '/', 2), '0')::numeric " \
      "WHEN #{raw} ~ '^[0-9]+$|^[0-9]+\\.[0-9]+$' " \
      "THEN #{raw}::numeric " \
      'ELSE NULL END'
  end

  def apply_labels
    return if filters[:labels].blank?

    min_confidence = filters[:label_min_confidence] || 0
    photo_ids = Label.where(name: filters[:labels]).where(confidence: min_confidence..).select(:photo_id)
    @relation = @relation.where(id: photo_ids)
  end

  def apply_license
    return if filters[:license].blank?

    unless License::VALUES.include?(filters[:license])
      @relation = @relation.none
      return
    end

    @relation =
      if filters[:license] == License::ALL_RIGHTS_RESERVED
        @relation.where(license: [License::ALL_RIGHTS_RESERVED, nil, ''])
      else
        @relation.where(license: filters[:license])
      end
  end

  # Admin-only in the UI, but not enforced here: applied on top of the
  # caller's Pundit-scoped relation, so a non-admin can only ever narrow
  # their own visible set (e.g. their own private photos), never widen it.
  def apply_privacy
    return if filters[:privacy].blank?

    unless Photo.privacies.key?(filters[:privacy].to_s)
      @relation = @relation.none
      return
    end

    @relation = @relation.where(privacy: filters[:privacy])
  end

  def apply_album
    if filters[:album_id].present?
      album = @album_scope.find_by(slug: filters[:album_id])
      @relation =
        if album
          @relation.where(id: AlbumsPhoto.where(album_id: album.id).select(:photo_id))
        else
          @relation.none
        end
    end

    return unless filters[:no_album]

    @relation = @relation.where.not(id: AlbumsPhoto.select(:photo_id))
  end

  def apply_missing_data
    if filters[:untagged]
      taggable_ids = ActsAsTaggableOn::Tagging.where(taggable_type: 'Photo').select(:taggable_id)
      @relation = @relation.where.not(id: taggable_ids)
    end

    @relation = @relation.where(title: [nil, '']) if filters[:no_title]
    @relation = @relation.where(description: [nil, '']) if filters[:no_description]
    @relation = @relation.where("taken_at IS NULL OR taken_at_source = 'unknown'") if filters[:unknown_date]
    @relation = @relation.where(taken_at_approximate: true) if filters[:approximate_date]
    @relation = @relation.where(scanned: true) if filters[:scanned]
  end

  def apply_sort
    if @sort == 'impressions_count'
      @relation = @relation.reorder(Arel.sql(
                                      "(photos.impressions_count + photos.flickr_impressions_count) #{@direction} NULLS LAST, photos.id #{@direction}"
                                    ))
    elsif (column = SORT_COLUMNS[@sort])
      @relation = @relation.reorder(Arel.sql("photos.#{column} #{@direction} NULLS LAST, photos.id #{@direction}"))
    elsif filters[:query].blank?
      # relevance with no text query: nothing to rank by, fall back to recency
      @relation = @relation.reorder(posted_at: :desc)
    end
    # relevance with a text query: keep pg_search's own rank order
  end
end
