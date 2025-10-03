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
    # quick unscoped photo count
    # photos_count = Photo.unscoped { albums_photos.count }

    @public_photos = all_photos(refetch: true).select(&:public?)

    @photos_count = all_photos.size
    public_photos_count = @public_photos.size

    pcpi, ucpi = cover_photo_ids

    maintenance_update(public_photos_count:, photos_count: @photos_count, public_cover_photo_id: pcpi,
                       user_cover_photo_id: ucpi)

    self
  end

  def all_photos(refetch: false)
    return @all_photos if @all_photos && !refetch

    @all_photos = Photo
                  .unscoped
                  .joins(:albums)
                  .where(albums: { id: })
                  .order('albums_photos.ordering')
                  .select('photos.id, photos.privacy')
  end

  def cover_photo_ids
    if @photos_count.positive?
      pcpi = @public_photos.first&.id
      ucp = all_photos.find { |p| p.id == user_cover_photo_id }
      ucpi = ucp&.id

      if ucp&.public?
        pcpi = ucpi
      elsif !ucp
        ucpi = nil
      end
    end
    [pcpi, ucpi]
  end

  def maintenance_update(
    public_photos_count:,
    photos_count:,
    public_cover_photo_id:,
    user_cover_photo_id:
  )
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
end
