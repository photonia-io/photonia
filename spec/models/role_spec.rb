# == Schema Information
#
# Table name: roles
#
#  id         :bigint           not null, primary key
#  name       :string
#  symbol     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'has a valid factory' do
    expect(build(:role)).to be_valid
  end

  describe 'validations' do
    subject { build(:role) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:symbol) }
    it { should validate_uniqueness_of(:symbol) }
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:users) }
  end

  describe 'seeds' do
    it 'is correctly set up' do
      expect(Role.count).to eq(2)
      expect(Role.find_by(name: 'Registered User')).to be_present
      expect(Role.find_by(name: 'Uploader')).to be_present
    end
  end
end
