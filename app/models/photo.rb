class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :flickr_id, use: :slugged

  include ImageUploader::Attachment(:image)

  acts_as_taggable_on :tags

  default_scope { where(privacy: 'public') }
end
