# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_user_claims
#
#  id                :bigint           not null, primary key
#  approved_at       :datetime
#  claim_type        :string           not null
#  denied_at         :datetime
#  reason            :text
#  status            :string           default("pending"), not null
#  verification_code :string
#  verified_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  flickr_user_id    :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_flickr_user_claims_on_active_user_and_flickr_user  (user_id,flickr_user_id) UNIQUE WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying])::text[]))
#  index_flickr_user_claims_on_flickr_user_id               (flickr_user_id)
#  index_flickr_user_claims_on_status                       (status)
#  index_flickr_user_claims_on_user_id                      (user_id)
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

    context 'when the existing claim on the same flickr user is denied' do
      let(:denied_claim) { create(:flickr_user_claim, :denied) }

      it 'allows a new pending claim' do
        retry_claim = build(:flickr_user_claim, user: denied_claim.user, flickr_user: denied_claim.flickr_user)

        expect(retry_claim).to be_valid
      end

      it 'allows another denied claim, in the database too' do
        expect do
          create(:flickr_user_claim, :denied, user: denied_claim.user, flickr_user: denied_claim.flickr_user)
        end.not_to raise_error
      end
    end

    it 'does not apply the uniqueness rule to a denied claim' do
      existing_claim = create(:flickr_user_claim)
      denied_duplicate = build(:flickr_user_claim, :denied, user: existing_claim.user, flickr_user: existing_claim.flickr_user)

      expect(denied_duplicate).to be_valid
    end

    context 'when the user already has an active claim on a different flickr user' do
      let(:user) { create(:user) }

      it 'is invalid when the user has a pending claim on another flickr user' do
        create(:flickr_user_claim, user: user, status: 'pending')
        second_claim = build(:flickr_user_claim, user: user, flickr_user: create(:flickr_user))

        expect(second_claim).not_to be_valid
        expect(second_claim.errors[:base])
          .to include('You already have a pending or approved claim on a different Flickr user')
      end

      it 'is invalid when the user has an approved claim on another flickr user' do
        create(:flickr_user_claim, :approved, user: user)
        second_claim = build(:flickr_user_claim, user: user, flickr_user: create(:flickr_user))

        expect(second_claim).not_to be_valid
        expect(second_claim.errors[:base])
          .to include('You already have a pending or approved claim on a different Flickr user')
      end

      it 'is valid when the user only has a denied claim on another flickr user' do
        create(:flickr_user_claim, :denied, user: user)
        second_claim = build(:flickr_user_claim, user: user, flickr_user: create(:flickr_user))

        expect(second_claim).to be_valid
      end

      it 'is valid when updating an existing claim (not just on create)' do
        claim = create(:flickr_user_claim, :approved, user: user)
        # created as denied (valid), then force-flipped to pending to simulate
        # pre-existing conflicting data without going through the create validation
        other_claim = create(:flickr_user_claim, :denied, user: user)
        other_claim.update_column(:status, 'pending')

        expect(claim.reload).to be_valid
      end
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

    it 'still approves when the flickr user is already claimed by the same user' do
      claim.flickr_user.update!(claimed_by_user: claim.user)

      expect { claim.approve! }.to change { claim.reload.status }.from('pending').to('approved')
    end

    context 'when the flickr user is already claimed by another user' do
      let(:other_user) { create(:user) }

      before { claim.flickr_user.update!(claimed_by_user: other_user) }

      it 'raises and leaves both records untouched' do
        expect { claim.approve! }.to raise_error(FlickrUserClaim::AlreadyClaimedError)
        expect(claim.reload).to be_pending
        expect(claim.flickr_user.reload.claimed_by_user).to eq(other_user)
      end
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
