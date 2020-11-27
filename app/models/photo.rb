class Photo < ApplicationRecord
  extend FriendlyId
  friendly_id :flickr_id, use: :slugged

  include ImageUploader::Attachment(:image)

  default_scope { where(privacy: 'public') }
end
