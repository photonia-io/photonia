class HomepageSerializer
  include JSONAPI::Serializer
  has_one :latest_photo, record_type: :photo
  has_one :random_photo, record_type: :photo
  has_many :most_used_tags
end
