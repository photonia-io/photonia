# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlickrUserClaimPolicy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:other_user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }
  let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user) }

  describe '#create?' do
    it 'allows authenticated users to create claims' do
      expect(FlickrUserClaimPolicy.new(user, FlickrUserClaim.new).create?).to be true
    end

    it 'denies guests to create claims' do
      expect(FlickrUserClaimPolicy.new(nil, FlickrUserClaim.new).create?).to be false
    end
  end

  describe '#verify?' do
    it 'allows users to verify their own pending claims' do
      expect(FlickrUserClaimPolicy.new(user, claim).verify?).to be true
    end

    it 'denies users to verify other users\' claims' do
      expect(FlickrUserClaimPolicy.new(other_user, claim).verify?).to be false
    end

    it 'denies users to verify non-pending claims' do
      claim.update!(status: 'approved')
      expect(FlickrUserClaimPolicy.new(user, claim).verify?).to be false
    end

    it 'denies guests to verify claims' do
      expect(FlickrUserClaimPolicy.new(nil, claim).verify?).to be false
    end
  end

  describe '#approve?' do
    it 'allows admins to approve claims' do
      expect(FlickrUserClaimPolicy.new(admin, claim).approve?).to be true
    end

    it 'denies non-admin users to approve claims' do
      expect(FlickrUserClaimPolicy.new(user, claim).approve?).to be false
    end

    it 'denies guests to approve claims' do
      expect(FlickrUserClaimPolicy.new(nil, claim).approve?).to be false
    end
  end

  describe '#deny?' do
    it 'allows admins to deny claims' do
      expect(FlickrUserClaimPolicy.new(admin, claim).deny?).to be true
    end

    it 'denies non-admin users to deny claims' do
      expect(FlickrUserClaimPolicy.new(user, claim).deny?).to be false
    end

    it 'denies guests to deny claims' do
      expect(FlickrUserClaimPolicy.new(nil, claim).deny?).to be false
    end
  end

  describe '#show?' do
    it 'allows users to see their own claims' do
      expect(FlickrUserClaimPolicy.new(user, claim).show?).to be true
    end

    it 'allows admins to see any claim' do
      expect(FlickrUserClaimPolicy.new(admin, claim).show?).to be true
    end

    it 'denies other users to see claims' do
      expect(FlickrUserClaimPolicy.new(other_user, claim).show?).to be false
    end

    it 'denies guests to see claims' do
      expect(FlickrUserClaimPolicy.new(nil, claim).show?).to be false
    end
  end

  describe '#index?' do
    it 'allows admins to list all claims' do
      expect(FlickrUserClaimPolicy.new(admin, FlickrUserClaim).index?).to be true
    end

    it 'denies non-admin users to list all claims' do
      expect(FlickrUserClaimPolicy.new(user, FlickrUserClaim).index?).to be false
    end

    it 'denies guests to list all claims' do
      expect(FlickrUserClaimPolicy.new(nil, FlickrUserClaim).index?).to be false
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
