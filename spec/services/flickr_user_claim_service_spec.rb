# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlickrUserClaimService do
  let(:user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }
  let(:service) { described_class.new(user, flickr_user) }

  describe '#request_automatic_claim' do
    it 'creates a new automatic claim with verification code' do
      claim = service.request_automatic_claim

      expect(claim).to be_persisted
      expect(claim.user).to eq(user)
      expect(claim.flickr_user).to eq(flickr_user)
      expect(claim.claim_type).to eq('automatic')
      expect(claim.status).to eq('pending')
      expect(claim.verification_code).to be_present
      expect(claim.verification_code.length).to eq(10)
    end
  end

  describe '#verify_automatic_claim' do
    let(:claim) { create(:flickr_user_claim, :automatic, user: user, flickr_user: flickr_user) }

    context 'when claim is valid and code is found in profile' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return("My profile description with code #{claim.verification_code} here")
      end

      it 'approves the claim and marks it as verified' do
        result = service.verify_automatic_claim(claim)

        expect(result[:success]).to be(true)
        expect(result[:claim].reload.status).to eq('approved')
        expect(result[:claim].verified_at).to be_present
        expect(result[:claim].approved_at).to be_present
        expect(flickr_user.reload.claimed_by_user).to eq(user)
      end
    end

    context 'when code is not found in profile' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return('My profile description without the code')
      end

      it 'returns error' do
        result = service.verify_automatic_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to include('Verification code not found')
        expect(claim.reload.status).to eq('pending')
      end
    end

    context 'when profile cannot be fetched' do
      before do
        allow(FlickrAPIService).to receive(:profile_get_profile_description)
          .with(flickr_user.nsid)
          .and_return(nil)
      end

      it 'returns error' do
        result = service.verify_automatic_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to include('Unable to fetch Flickr profile')
      end
    end

    context 'when claim is not pending' do
      let(:claim) { create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user) }

      it 'returns error' do
        result = service.verify_automatic_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Claim is not pending')
      end
    end

    context 'when claim is not automatic' do
      let(:claim) { create(:flickr_user_claim, :manual, user: user, flickr_user: flickr_user) }

      it 'returns error' do
        result = service.verify_automatic_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid claim type')
      end
    end
  end

  describe '#request_manual_claim' do
    let(:admin) { create(:user, admin: true) }
    let(:reason) { 'Lost access to my Flickr account' }

    before do
      allow(AdminMailer).to receive_message_chain(:with, :flickr_claim_request, :deliver_later)
    end

    it 'creates a manual claim and sends email to admins' do
      claim = service.request_manual_claim(reason: reason)

      expect(claim).to be_persisted
      expect(claim.user).to eq(user)
      expect(claim.flickr_user).to eq(flickr_user)
      expect(claim.claim_type).to eq('manual')
      expect(claim.status).to eq('pending')
      expect(claim.reason).to eq(reason)
    end

    it 'sends email to admins' do
      admin # ensure admin exists
      expect(AdminMailer).to receive(:with).with(
        admin_emails: [admin.email],
        user: user,
        flickr_user: flickr_user,
        claim: instance_of(FlickrUserClaim),
        reason: reason
      ).and_return(double(flickr_claim_request: double(deliver_later: true)))

      service.request_manual_claim(reason: reason)
    end
  end

  describe '#approve_claim' do
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

    before do
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_approved, :deliver_later)
    end

    context 'when claim is valid' do
      it 'approves the claim' do
        result = service.approve_claim(claim)

        expect(result[:success]).to be(true)
        expect(result[:claim].reload.status).to eq('approved')
        expect(result[:claim].approved_at).to be_present
        expect(flickr_user.reload.claimed_by_user).to eq(user)
      end

      it 'sends email to user' do
        expect(UserMailer).to receive(:with).with(
          user: user,
          flickr_user: flickr_user
        ).and_return(double(flickr_claim_approved: double(deliver_later: true)))

        service.approve_claim(claim)
      end
    end

    context 'when claim is not pending' do
      let(:claim) { create(:flickr_user_claim, :approved, user: user, flickr_user: flickr_user) }

      it 'returns error' do
        result = service.approve_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Claim is not pending')
      end
    end
  end

  describe '#deny_claim' do
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

    before do
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_denied, :deliver_later)
    end

    context 'when claim is valid' do
      it 'denies the claim' do
        result = service.deny_claim(claim)

        expect(result[:success]).to be(true)
        expect(result[:claim].reload.status).to eq('denied')
        expect(result[:claim].denied_at).to be_present
      end

      it 'sends email to user' do
        expect(UserMailer).to receive(:with).with(
          user: user,
          flickr_user: flickr_user
        ).and_return(double(flickr_claim_denied: double(deliver_later: true)))

        service.deny_claim(claim)
      end
    end

    context 'when claim is not pending' do
      let(:claim) { create(:flickr_user_claim, :denied, user: user, flickr_user: flickr_user) }

      it 'returns error' do
        result = service.deny_claim(claim)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Claim is not pending')
      end
    end
  end

  describe '.approve_claim_by_token' do
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }
    let(:token) { described_class.generate_token(claim) }

    before do
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_approved, :deliver_later)
    end

    context 'with valid token' do
      it 'approves the claim' do
        result = described_class.approve_claim_by_token(claim.id, token)

        expect(result[:success]).to be(true)
        expect(result[:claim].reload.status).to eq('approved')
      end
    end

    context 'with invalid token' do
      it 'returns error' do
        result = described_class.approve_claim_by_token(claim.id, 'invalid_token')

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid token')
      end
    end

    context 'with tampered token' do
      it 'returns error for signature mismatch' do
        # Create a token for a different claim
        other_claim = create(:flickr_user_claim)
        tampered_token = described_class.generate_token(other_claim)

        result = described_class.approve_claim_by_token(claim.id, tampered_token)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid token')
      end
    end

    context 'with non-existent claim' do
      it 'returns error' do
        non_existent_id = (FlickrUserClaim.maximum(:id) || 0) + 1
        result = described_class.approve_claim_by_token(non_existent_id, token)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Claim not found')
      end
    end
  end

  describe '.deny_claim_by_token' do
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }
    let(:token) { described_class.generate_token(claim) }

    before do
      allow(UserMailer).to receive_message_chain(:with, :flickr_claim_denied, :deliver_later)
    end

    context 'with valid token' do
      it 'denies the claim' do
        result = described_class.deny_claim_by_token(claim.id, token)

        expect(result[:success]).to be(true)
        expect(result[:claim].reload.status).to eq('denied')
      end
    end

    context 'with invalid token' do
      it 'returns error' do
        result = described_class.deny_claim_by_token(claim.id, 'invalid_token')

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid token')
      end
    end

    context 'with tampered token' do
      it 'returns error for signature mismatch' do
        # Create a token for a different claim
        other_claim = create(:flickr_user_claim)
        tampered_token = described_class.generate_token(other_claim)

        result = described_class.deny_claim_by_token(claim.id, tampered_token)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid token')
      end
    end
  end

  describe '.generate_token' do
    let(:claim) { create(:flickr_user_claim) }

    it 'generates a consistent token for the same claim' do
      token1 = described_class.generate_token(claim)
      token2 = described_class.generate_token(claim)

      expect(token1).to eq(token2)
    end

    it 'generates a signed token string' do
      token = described_class.generate_token(claim)

      expect(token).to be_a(String)
      expect(token.length).to be > 20
    end

    it 'generates different tokens for different claims' do
      claim2 = create(:flickr_user_claim)
      token1 = described_class.generate_token(claim)
      token2 = described_class.generate_token(claim2)

      expect(token1).not_to eq(token2)
    end
  end

  describe '#undo_claim' do
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

    context 'when claim is pending' do
      it 'deletes the claim' do
        result = service.undo_claim(claim)

        expect(result[:success]).to be(true)
        expect(FlickrUserClaim.find_by(id: claim.id)).to be_nil
        expect(flickr_user.reload.claimed_by_user).to be_nil
      end
    end

    context 'when claim is approved' do
      before do
        claim.approve!
      end

      it 'removes the claimed_by_user association and deletes the claim' do
        expect(flickr_user.reload.claimed_by_user).to eq(user)

        result = service.undo_claim(claim)

        expect(result[:success]).to be(true)
        expect(FlickrUserClaim.find_by(id: claim.id)).to be_nil
        expect(flickr_user.reload.claimed_by_user).to be_nil
      end
    end

    context 'when claim is denied' do
      before do
        claim.deny!
      end

      it 'deletes the claim without affecting the flickr_user' do
        result = service.undo_claim(claim)

        expect(result[:success]).to be(true)
        expect(FlickrUserClaim.find_by(id: claim.id)).to be_nil
        expect(flickr_user.reload.claimed_by_user).to be_nil
      end
    end

    context 'when claim is nil' do
      it 'returns an error' do
        result = service.undo_claim(nil)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Claim not found')
      end
    end
  end
end
