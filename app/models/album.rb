# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  photos_count             :integer          default(0), not null
#  privacy                  :enum             default("public")
#  public_photos_count      :integer          default(0), not null
#  serial_number            :bigint
#  slug                     :string
#  sorting_order            :string           default("asc"), not null
#  sorting_type             :string           default("taken_at"), not null
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  public_cover_photo_id    :bigint
#  user_cover_photo_id      :bigint
#  user_id                  :bigint           default(1), not null
#
# Indexes
#
#  index_albums_on_public_cover_photo_id  (public_cover_photo_id)
#  index_albums_on_user_cover_photo_id    (user_cover_photo_id)
#  index_albums_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Album < ApplicationRecord
  enum :sorting_type, {
    taken_at: 'taken_at',
    posted_at: 'posted_at',
    title: 'title',
    manual: 'manual'
  }, suffix: true

  enum :sorting_order, {
    asc: 'asc',
    desc: 'desc'
  }, suffix: true

  is_impressionable counter_cache: true, unique: :session_hash

  extend FriendlyId

  friendly_id :serial_number, use: :slugged

  include SerialNumberSetter

  before_validation :set_serial_number, prepend: true

  include HtmlDescriptionable
  include TrackableTitleAndDescription

  after_create :maintenance
  after_update :maintenance

  default_scope { where(privacy: 'public') }

  validates :title, presence: true

  belongs_to :user
  has_many :albums_photos, dependent: :destroy, inverse_of: :album
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :photos, through: :albums_photos
  belongs_to :public_cover_photo, class_name: 'Photo', optional: true
  belongs_to :user_cover_photo, class_name: 'Photo', optional: true

  def maintenance
    apply_automatic_photo_ordering! if automatic_ordering?

    @public_photos = all_photos(refetch: true).select(&:public?)
    public_photos_count = @public_photos.size

    @photos_count = all_photos.size

    # pcpi - public_cover_photo_id
    # ucpi - user_cover_photo_id
    pcpi, ucpi = cover_photo_ids

    maintenance_update(public_photos_count:, photos_count: @photos_count, public_cover_photo_id: pcpi,
                       user_cover_photo_id: ucpi)

    self
  end

  def all_photos(refetch: false, unordered: false)
    return @all_photos if @all_photos && !refetch

    @all_photos = Photo
                  .unscoped
                  .joins(:albums)
                  .where(albums: { id: })
                  .select('photos.id, photos.privacy')

    @all_photos = unordered ? @all_photos : @all_photos.order('albums_photos.ordering')
  end

  def cover_photo_ids
    return [nil, nil] unless @photos_count.positive?

    pcpi = public_cover_photo_id_candidate
    ucpi = user_cover_photo_id_candidate

    pcpi = ucpi if user_cover_photo_is_public?(ucpi)
    ucpi = nil unless user_cover_photo_exists?(ucpi)

    [pcpi, ucpi]
  end

  def maintenance_update(
    public_photos_count:,
    photos_count:,
    public_cover_photo_id:,
    user_cover_photo_id:
  )
    # Skip validations and callbacks to avoid infinite loops
    # rubocop:disable Rails/SkipsModelValidations
    if self.public_photos_count != public_photos_count ||
       self.photos_count != photos_count ||
       self.public_cover_photo_id != public_cover_photo_id ||
       self.user_cover_photo_id != user_cover_photo_id
      update_columns(public_photos_count:, photos_count:, public_cover_photo_id:, user_cover_photo_id:)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  scope :albums_with_photos, lambda { |photo_ids:, user_id:, ids_are_slugs: false|
    where_clause = ids_are_slugs ? { slug: photo_ids } : { id: photo_ids }
    Photo.unscoped
         .joins(:albums)
         .where(where_clause)
         .where(albums: { user_id: })
         .where(user_id:)
         .group('albums.id')
         .select('albums.slug, albums.title, COUNT(photos.id) AS contained_photos_count')
  }

  def manual_ordering?
    sorting_type == 'manual'
  end

  def automatic_ordering?
    !manual_ordering?
  end

  def apply_automatic_photo_ordering!
    return if manual_ordering?

    albums_photos = AlbumsPhoto.where(album_id: id).to_a
    update_albums_photos_ordering(albums_photos)
  end

  def execute_bulk_ordering_update(ids_and_orderings)
    ids = ids_and_orderings.pluck(:id)
    case_sql = ids_and_orderings.map { |iao| "WHEN #{iao[:id]} THEN #{iao[:ordering]}" }.join(' ')

    # We should skip validations and callbacks to avoid infinite loops
    # Also this is a bulk update, and the data is already validated
    # rubocop:disable Rails/SkipsModelValidations
    AlbumsPhoto.where(id: ids).update_all("ordering = CASE id #{case_sql} END")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def photos_ordered_by_sorting_fields
    return @ordered_photos if @ordered_photos

    all_photos = all_photos(refetch: true, unordered: true)

    return @ordered_photos = all_photos.order('albums_photos.ordering ASC') if sorting_type == 'manual'

    @ordered_photos = all_photos.order(sorting_type.to_sym => sorting_order.to_sym)
  end

  private

  def public_cover_photo_id_candidate
    @public_photos.first&.id
  end

  def user_cover_photo_id_candidate
    ucp = all_photos.find { |p| p.id == user_cover_photo_id }
    ucp&.id
  end

  def user_cover_photo_is_public?(ucpi)
    ucp = all_photos.find { |p| p.id == ucpi }
    ucp&.public?
  end

  def user_cover_photo_exists?(ucpi)
    ucpi.present?
  end

  def update_albums_photos_ordering(albums_photos)
    ids_and_orderings = build_ordering_mapping(albums_photos)
    return unless ids_and_orderings.any?

    execute_bulk_ordering_update(ids_and_orderings)
  end

  def build_ordering_mapping(albums_photos)
    albums_photos.map do |ap|
      photo_index = photos_ordered_by_sorting_fields.index { |p| p.id == ap.photo_id }
      { id: ap.id, ordering: (photo_index + 1) * 100_000 }
    end
  end
end
