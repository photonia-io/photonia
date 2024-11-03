# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  admin               :boolean          default(FALSE)
#  display_name        :string
#  email               :string           default(""), not null
#  encrypted_password  :string           default(""), not null
#  first_name          :string
#  jti                 :string
#  last_name           :string
#  remember_created_at :datetime
#  serial_number       :bigint
#  slug                :string
#  timezone            :string           default("UTC"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_jti    (jti) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  it 'has a valid factory' do
    expect(build(:user)).to be_valid
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:timezone) }
  end

  describe 'scopes' do
    describe '.admins' do
      it 'returns only the admin users' do
        admin = create(:user, admin: true)
        create(:user, admin: false)

        expect(described_class.admins).to eq([admin])
      end
    end
  end

  describe '.find_or_create_from_social' do
    let(:email) { 'test@test.com' }
    let(:first_name) { 'Test' }
    let(:last_name) { 'User' }
    let(:display_name) { 'Test User' }

    context 'when the user exists' do
      let!(:user) { create(:user, email: email) }

      it 'returns the user and false' do
        expect(described_class.find_or_create_from_social(email: email)).to eq([user, false])
      end
    end

    context 'when the user does not exist' do
      it 'creates a new user and true' do
        user, created = described_class.find_or_create_from_social(
          email: email,
          first_name: first_name,
          last_name: last_name,
          display_name: display_name
        )

        expect(user).to be_persisted
        expect(user.email).to eq(email)
        expect(user.first_name).to eq(first_name)
        expect(user.last_name).to eq(last_name)
        expect(user.display_name).to eq(display_name)
        expect(created).to be(true)
      end
    end
  end

  describe '#slug' do
    it 'returns the correct slug' do
      user = create(:user)
      expect(user.slug).to eq(user.serial_number.to_s)
    end
  end

  describe 'serial number setting' do
    it 'sets the serial number before validation' do
      user = build(:user)
      user.valid?
      expect(user.serial_number).not_to be_blank
    end

    it 'generates a serial number if it is not set' do
      user = build(:user, serial_number: nil)
      expect { user.valid? }.to change(user, :serial_number).from(nil)
    end

    it 'does not overwrite the serial number if it is already set' do
      user = build(:user, serial_number: 123)
      user.valid?
      expect(user.serial_number).to eq(123)
    end
  end
end
