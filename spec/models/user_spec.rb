# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  admin                       :boolean          default(FALSE)
#  created_from_facebook       :boolean          default(FALSE), not null
#  disabled                    :boolean          default(FALSE), not null
#  display_name                :string
#  email                       :string           default(""), not null
#  encrypted_password          :string           default(""), not null
#  facebook_data_deletion_code :string
#  first_name                  :string
#  jti                         :string
#  last_name                   :string
#  remember_created_at         :datetime
#  serial_number               :bigint
#  signup_provider             :string           default("local"), not null
#  slug                        :string
#  timezone                    :string           default("UTC"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  facebook_user_id            :string
#
# Indexes
#
#  index_users_on_email                        (email) UNIQUE
#  index_users_on_facebook_data_deletion_code  (facebook_data_deletion_code) UNIQUE
#  index_users_on_facebook_user_id             (facebook_user_id) UNIQUE
#  index_users_on_jti                          (jti) UNIQUE
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
    it { should validate_inclusion_of(:signup_provider).in_array(%w[local facebook google]) }
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

  describe '.find_or_create_from_provider' do
    let(:email) { 'test@test.com' }
    let(:provider) { %w[facebook google].sample }
    let(:first_name) { 'Test' }
    let(:last_name) { 'User' }
    let(:display_name) { 'Test User' }

    context 'when the user exists' do
      let!(:user) { create(:user, email: email) }

      it 'returns the user and false' do
        expect(described_class.find_or_create_from_provider(email:, provider:)).to eq([user, false])
      end
    end

    context 'when the user does not exist' do
      it 'creates a new user returns it and true' do
        user, created = described_class.find_or_create_from_provider(
          email: email,
          provider: provider,
          first_name: first_name,
          last_name: last_name,
          display_name: display_name
        )

        expect(user).to be_persisted
        expect(user.email).to eq(email)
        expect(user.signup_provider).to eq(provider)
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

  describe 'roles' do
    let(:user) { create(:user) }

    it 'has a default role' do
      expect(user.roles).to eq([Role.find_by(symbol: 'registered_user')])
    end

    it 'can have multiple roles' do
      role = create(:role, name: 'Another role', symbol: 'another_role')
      user.roles << role

      expect(user.roles).to include(role)
    end
  end

  describe '#has_role?' do
    let(:user) { create(:user) }

    it 'returns true if the user is an admin' do
      user.update(admin: true)
      expect(user.has_role?(:non_existent_role)).to be(true)
    end

    it 'returns true if the user has the role' do
      role = create(:role, name: 'Another role', symbol: 'another_role')
      user.roles << role

      expect(user.has_role?(:another_role)).to be(true)
    end

    it 'returns false if the user does not have the role' do
      expect(user.has_role?(:non_existent_role)).to be(false)
    end
  end
end
