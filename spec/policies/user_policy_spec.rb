# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class.new(current_user, user) }

  let(:user) { create(:user) }

  context 'with visitors' do
    let(:current_user) { nil }

    it { is_expected.to forbid_all_actions }
  end

  context 'with registered users' do
    let(:current_user) { create(:user) }

    it { is_expected.to forbid_all_actions }

    context 'when the current user is the same as the user' do
      let(:current_user) { user }

      it { is_expected.to permit_only_actions(%i[edit update]) }
    end
  end

  context 'with admins' do
    let(:current_user) { create(:user, admin: true) }

    it { is_expected.to permit_only_actions(%i[edit update]) }
  end
end
