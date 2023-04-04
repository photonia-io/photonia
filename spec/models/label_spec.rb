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
require 'rails_helper'

RSpec.describe Label, type: :model do
  it 'has a valid factory' do
    expect(build(:label)).to be_valid
  end

  describe '#center' do
    it 'returns the center of the label' do
      label = build(:label, left: 0.20, top: 0.10, width: 0.5, height: 0.6)
      expect(label.center.left).to eq(0.45)      
      expect(label.center.top).to eq(0.4)
    end
  end

  describe '#area' do
    it 'returns the area of the label' do
      label = build(:label, left: 0.20, top: 0.10, width: 0.5, height: 0.6)
      expect(label.area).to eq(49)
    end
  end

  describe '#person?' do
    it 'returns true if the label is a person' do
      label = build(:label, name: 'Person')
      expect(label.person?).to eq(true)
    end

    it 'returns false if the label is not a person' do
      label = build(:label, name: 'Cat')
      expect(label.person?).to eq(false)
    end
  end

  describe '#bounding_box' do
    let(:left) { 0.20 }  
    let(:top) { 0.10 }
    let(:width) { 0.5 }
    let(:height) { 0.6 }
    
    it 'returns the bounding box of the label' do
      label = build(:label, left: left, top: top, width: width, height: height)
      expect(label.bounding_box.left).to eq(left)
      expect(label.bounding_box.top).to eq(top)
      expect(label.bounding_box.width).to eq(width)
      expect(label.bounding_box.height).to eq(height)
    end
  end
end
