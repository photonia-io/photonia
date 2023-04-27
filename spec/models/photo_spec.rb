# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photo do
  it 'has a valid factory' do
    expect(build(:photo)).to be_valid
  end

  describe 'validations' do
    it 'is invalid without a name' do
      expect(build(:photo, name: nil)).not_to be_valid
    end

    it 'is invalid without a description' do
      expect(build(:photo, description: nil)).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many albums' do
      association = described_class.reflect_on_association(:albums)
      expect(association.macro).to eq :has_many
    end

    it 'has many albums through albums_photos' do
      association = described_class.reflect_on_association(:albums)
      expect(association.options[:through]).to eq :albums_photos
    end

    it 'has many labels' do
      association = described_class.reflect_on_association(:labels)
      expect(association.macro).to eq :has_many
    end
  end

  describe 'callbacks' do
    it 'calls set_fields before validation' do
      photo = build(:photo)
      expect(photo).to receive(:set_fields)
      photo.valid?
    end
  end

  describe 'instance methods' do
    describe '#next' do
      it 'returns the next photo' do
        photo = create(:photo)
        next_photo = create(:photo, imported_at: photo.imported_at + 1.day)
        expect(photo.next).to eq(next_photo)
      end
    end

    describe '#prev' do
      it 'returns the previous photo' do
        photo = create(:photo)
        prev_photo = create(:photo, imported_at: photo.imported_at - 1.day)
        expect(photo.prev).to eq(prev_photo)
      end
    end
  end
end
