class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :flickr_id, use: :slugged

  include ImageUploader::Attachment(:image)

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :name
      indexes :description
      indexes :tags
    end
  end

  acts_as_taggable_on :tags

  default_scope { where(privacy: 'public') }

  def next
    Photo.where('date_taken > ?', date_taken).order(:date_taken).first
  end

  def prev
    Photo.where('date_taken < ?', date_taken).order(date_taken: :desc).first
  end
end
