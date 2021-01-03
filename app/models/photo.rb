class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include ImageUploader::Attachment(:image)

  include PgSearch::Model
  pg_search_scope :search,
                  against: [:name, :description],
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

  before_validation :set_serial_number, prepend: true

  def next
    Photo.where('date_taken > ?', date_taken).order(:date_taken).first
  end

  def prev
    Photo.where('date_taken < ?', date_taken).order(date_taken: :desc).first
  end

  private

  def set_serial_number
    if self.serial_number == nil
      maximum_serial_number = Photo.unscoped.maximum('serial_number') || 1_000_000_000
      self.serial_number = maximum_serial_number + rand(1..10_000_000)
    end
  end
end
