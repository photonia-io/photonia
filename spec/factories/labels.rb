# frozen_string_literal: true

# == Schema Information
#
# Table name: labels
#
#  id         :bigint           not null, primary key
#  confidence :float
#  height     :float
#  left       :float
#  name       :string
#  top        :float
#  width      :float
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  photo_id   :bigint           not null
#
# Indexes
#
#  index_labels_on_photo_id  (photo_id)
#
# Foreign Keys
#
#  fk_rails_...  (photo_id => photos.id)
#
FactoryBot.define do
  factory :label do
    name { Faker::Lorem.word }
    confidence { 1.0 }
    top { 0.5 }
    left { 0.5 }
    width { 0.5 }
    height { 0.5 }

    photo
  end
end
