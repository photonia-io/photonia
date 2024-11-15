# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotoPolicy do
  subject { described_class.new(current_user, photo) }

  let(:user) { create(:user, :uploader) }
  let(:photo) { create(:photo, user: user) }

  context 'with visitors' do
    let(:current_user) { nil }

    it { is_expected.to permit_only_actions(%i[index show]) }
  end

  context 'with registered users' do
    let(:current_user) { create(:user) }

    it { is_expected.to permit_only_actions(%i[index show]) }
  end

  context 'with uploaders' do
    let(:current_user) { create(:user, :uploader) }

    it { is_expected.to forbid_only_actions(%i[edit update destroy]) }

    context 'owning the photo' do
      let(:current_user) { user }

      it { is_expected.to permit_all_actions }
    end
  end

  context 'with admins' do
    let(:current_user) { create(:user, admin: true) }

    it { is_expected.to permit_all_actions }
  end
end
