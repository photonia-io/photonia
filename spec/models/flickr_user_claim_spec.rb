# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_user_claims
#
#  id                 :bigint           not null, primary key
#  claim_type         :string           not null
#  reason             :text
#  status             :string           default("pending"), not null
#  verification_code  :string
#  approved_at        :datetime
#  denied_at          :datetime
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  flickr_user_id     :bigint           not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_flickr_user_claims_on_flickr_user_id              (flickr_user_id)
#  index_flickr_user_claims_on_status                      (status)
#  index_flickr_user_claims_on_user_id                     (user_id)
#  index_flickr_user_claims_on_user_id_and_flickr_user_id  (user_id,flickr_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (flickr_user_id => flickr_users.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe FlickrUserClaim do
  describe 'validations' do
    subject { build(:flickr_user_claim) }

    it { should validate_presence_of(:claim_type) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:claim_type).in_array(%w[automatic manual]) }
    it { should validate_inclusion_of(:status).in_array(%w[pending approved denied]) }

    context 'when claim_type is automatic' do
      subject { build(:flickr_user_claim, :automatic) }

      it { should validate_presence_of(:verification_code) }
    end

    context 'when claim_type is manual' do
      subject { build(:flickr_user_claim, :manual) }

      it { should_not validate_presence_of(:verification_code) }
    end

    it 'validates uniqueness of user_id scoped to flickr_user_id' do
      existing_claim = create(:flickr_user_claim)
      duplicate_claim = build(:flickr_user_claim, user: existing_claim.user, flickr_user: existing_claim.flickr_user)

      expect(duplicate_claim).not_to be_valid
      expect(duplicate_claim.errors[:user_id]).to include('has already claimed this Flickr user')
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:flickr_user) }
  end

  describe 'scopes' do
    let!(:pending_claim) { create(:flickr_user_claim, status: 'pending') }
    let!(:approved_claim) { create(:flickr_user_claim, :approved) }
    let!(:denied_claim) { create(:flickr_user_claim, :denied) }
    let!(:automatic_claim) { create(:flickr_user_claim, :automatic) }
    let!(:manual_claim) { create(:flickr_user_claim, :manual) }

    describe '.pending' do
      it 'returns only pending claims' do
        expect(described_class.pending).to include(pending_claim)
        expect(described_class.pending).not_to include(approved_claim, denied_claim)
      end
    end

    describe '.approved' do
      it 'returns only approved claims' do
        expect(described_class.approved).to include(approved_claim)
        expect(described_class.approved).not_to include(pending_claim, denied_claim)
      end
    end

    describe '.denied' do
      it 'returns only denied claims' do
        expect(described_class.denied).to include(denied_claim)
        expect(described_class.denied).not_to include(pending_claim, approved_claim)
      end
    end

    describe '.automatic' do
      it 'returns only automatic claims' do
        expect(described_class.automatic).to include(automatic_claim)
        expect(described_class.automatic).not_to include(manual_claim)
      end
    end

    describe '.manual' do
      it 'returns only manual claims' do
        expect(described_class.manual).to include(manual_claim)
        expect(described_class.manual).not_to include(automatic_claim)
      end
    end
  end

  describe '#approve!' do
    let(:claim) { create(:flickr_user_claim) }

    it 'approves the claim and updates the flickr_user' do
      expect { claim.approve! }.to change { claim.reload.status }.from('pending').to('approved')
      expect(claim.approved_at).to be_present
      expect(claim.flickr_user.claimed_by_user).to eq(claim.user)
    end
  end

  describe '#deny!' do
    let(:claim) { create(:flickr_user_claim) }

    it 'denies the claim' do
      expect { claim.deny! }.to change { claim.reload.status }.from('pending').to('denied')
      expect(claim.denied_at).to be_present
    end
  end

  describe '#pending?' do
    it 'returns true for pending claims' do
      claim = create(:flickr_user_claim, status: 'pending')
      expect(claim.pending?).to be(true)
    end

    it 'returns false for non-pending claims' do
      claim = create(:flickr_user_claim, :approved)
      expect(claim.pending?).to be(false)
    end
  end

  describe '#approved?' do
    it 'returns true for approved claims' do
      claim = create(:flickr_user_claim, :approved)
      expect(claim.approved?).to be(true)
    end

    it 'returns false for non-approved claims' do
      claim = create(:flickr_user_claim, status: 'pending')
      expect(claim.approved?).to be(false)
    end
  end

  describe '#denied?' do
    it 'returns true for denied claims' do
      claim = create(:flickr_user_claim, :denied)
      expect(claim.denied?).to be(true)
    end

    it 'returns false for non-denied claims' do
      claim = create(:flickr_user_claim, status: 'pending')
      expect(claim.denied?).to be(false)
    end
  end

  describe '#automatic?' do
    it 'returns true for automatic claims' do
      claim = create(:flickr_user_claim, :automatic)
      expect(claim.automatic?).to be(true)
    end

    it 'returns false for non-automatic claims' do
      claim = create(:flickr_user_claim, :manual)
      expect(claim.automatic?).to be(false)
    end
  end

  describe '#manual?' do
    it 'returns true for manual claims' do
      claim = create(:flickr_user_claim, :manual)
      expect(claim.manual?).to be(true)
    end

    it 'returns false for non-manual claims' do
      claim = create(:flickr_user_claim, :automatic)
      expect(claim.manual?).to be(false)
    end
  end
end
