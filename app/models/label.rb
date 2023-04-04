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
class Label < ApplicationRecord
  belongs_to :photo

  attr_accessor :sequenced_name

  def center
    Photo::Point.new(
      top + (height / 2),
      left + (width / 2)
    )
  end

  def area
    100 * (top + height) * (left + width)
  end

  def person?
    name == 'Person'
  end

  def bounding_box
    Photo::BoundingBox.new(top: top, left: left, width: width, height: height)
  end

  # class methods

  def self.find_or_create_from_rekognition_label_instance(photo, label_name, label_instance)
    Label.find_or_create_by(
      photo:,
      name: label_name,
      confidence: label_instance['confidence'],
      top: label_instance['bounding_box']['top'],
      left: label_instance['bounding_box']['left'],
      width: label_instance['bounding_box']['width'],
      height: label_instance['bounding_box']['height']
    )
  end
end
