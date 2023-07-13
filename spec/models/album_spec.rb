# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  serial_number            :bigint
#  slug                     :string
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint           default(1), not null
#
# Indexes
#
#  index_albums_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Album do
  it 'has a valid factory' do
    expect(build(:album)).to be_valid
  end

  describe 'validations' do
    it 'is invalid without a title' do
      expect(build(:album, title: nil)).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many photos through albums_photos' do
      association = described_class.reflect_on_association(:photos)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :albums_photos
    end
  end

  describe 'callbacks' do
    it 'calls set_serial_number before validation' do
      album = build(:album)
      expect(album).to receive(:set_serial_number)
      album.valid?
    end
  end

  describe 'instance methods' do
    it 'returns the correct slug' do
      album = create(:album)
      expect(album.slug).to eq(album.serial_number.to_s)
    end
  end
end
