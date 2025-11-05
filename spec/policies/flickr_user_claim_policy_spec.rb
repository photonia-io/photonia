# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlickrUserClaimPolicy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:other_user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }
  let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

  permissions :create? do
    it 'allows authenticated users to create claims' do
      expect(subject).to permit(user, FlickrUserClaim.new)
    end

    it 'denies guests to create claims' do
      expect(subject).not_to permit(nil, FlickrUserClaim.new)
    end
  end

  permissions :verify? do
    it 'allows users to verify their own pending claims' do
      expect(subject).to permit(user, claim)
    end

    it 'denies users to verify other users\' claims' do
      expect(subject).not_to permit(other_user, claim)
    end

    it 'denies users to verify non-pending claims' do
      claim.update!(status: 'approved')
      expect(subject).not_to permit(user, claim)
    end

    it 'denies guests to verify claims' do
      expect(subject).not_to permit(nil, claim)
    end
  end

  permissions :approve? do
    it 'allows admins to approve claims' do
      expect(subject).to permit(admin, claim)
    end

    it 'denies non-admin users to approve claims' do
      expect(subject).not_to permit(user, claim)
    end

    it 'denies guests to approve claims' do
      expect(subject).not_to permit(nil, claim)
    end
  end

  permissions :deny? do
    it 'allows admins to deny claims' do
      expect(subject).to permit(admin, claim)
    end

    it 'denies non-admin users to deny claims' do
      expect(subject).not_to permit(user, claim)
    end

    it 'denies guests to deny claims' do
      expect(subject).not_to permit(nil, claim)
    end
  end

  permissions :show? do
    it 'allows users to see their own claims' do
      expect(subject).to permit(user, claim)
    end

    it 'allows admins to see any claim' do
      expect(subject).to permit(admin, claim)
    end

    it 'denies other users to see claims' do
      expect(subject).not_to permit(other_user, claim)
    end

    it 'denies guests to see claims' do
      expect(subject).not_to permit(nil, claim)
    end
  end

  permissions :index? do
    it 'allows admins to list all claims' do
      expect(subject).to permit(admin, FlickrUserClaim)
    end

    it 'denies non-admin users to list all claims' do
      expect(subject).not_to permit(user, FlickrUserClaim)
    end

    it 'denies guests to list all claims' do
      expect(subject).not_to permit(nil, FlickrUserClaim)
    end
  end

  describe 'Scope' do
    let!(:user_claim) { create(:flickr_user_claim, user: user) }
    let!(:other_claim) { create(:flickr_user_claim, user: other_user) }

    context 'when user is admin' do
      it 'returns all claims' do
        scope = Pundit.policy_scope!(admin, FlickrUserClaim)
        expect(scope).to include(user_claim, other_claim)
      end
    end

    context 'when user is not admin' do
      it 'returns only their own claims' do
        scope = Pundit.policy_scope!(user, FlickrUserClaim)
        expect(scope).to include(user_claim)
        expect(scope).not_to include(other_claim)
      end
    end
  end
end
