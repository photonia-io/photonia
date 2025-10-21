# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlbumPolicy do
  subject { described_class.new(current_user, album) }

  let(:user) { create(:user, :uploader) }
  let(:album) { create(:album, user: user) }

  context 'with visitors' do
    let(:current_user) { nil }

    it { should permit_only_actions(%i[index show]) }
  end

  context 'with registered users' do
    let(:current_user) { create(:user) }

    it { should permit_only_actions(%i[index show]) }
  end

  context 'with uploaders' do
    let(:current_user) { create(:user, :uploader) }

    it { should forbid_only_actions(%i[edit update destroy]) }

    context 'when they own the album' do
      let(:current_user) { user }

      it { should permit_all_actions }
    end
  end

  context 'with admins' do
    let(:current_user) { create(:user, admin: true) }

    it { should permit_all_actions }
  end

  describe 'scope' do
    let(:me) { create(:user) }
    let(:other) { create(:user) }

    let!(:public_me) { create(:album, user: me, privacy: :public) }
    let!(:private_me) { create(:album, user: me, privacy: :private) }
    let!(:fandf_me) { create(:album, user: me, privacy: :friends_and_family) }

    let!(:public_other) { create(:album, user: other, privacy: :public) }
    let!(:private_other) { create(:album, user: other, privacy: :private) }
    let!(:fandf_other) { create(:album, user: other, privacy: :friends_and_family) }

    def resolve_for(user)
      described_class::Scope.new(user, Album.unscoped).resolve
    end

    context 'when visitor' do
      it 'returns only public albums' do
        result = resolve_for(nil)
        expect(result).to contain_exactly(public_me, public_other)
      end
    end

    context 'when logged-in user' do
      it 'returns public albums + own albums of any privacy' do
        result = resolve_for(me)
        expect(result).to contain_exactly(public_me, private_me, fandf_me, public_other)
      end
    end

    context 'when admin user' do
      it 'returns all albums regardless of privacy' do
        admin = create(:user, admin: true)
        result = resolve_for(admin)
        expect(result).to contain_exactly(public_me, private_me, fandf_me, public_other, private_other, fandf_other)
      end
    end
  end
end
