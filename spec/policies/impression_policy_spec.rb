# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImpressionPolicy do
  subject { described_class.new(current_user, impression) }

  let(:impression) { Impression.new }

  context 'with visitors' do
    let(:current_user) { nil }

    it { is_expected.to forbid_all_actions }
  end

  context 'with registered users' do
    let(:current_user) { create(:user) }

    it { is_expected.to forbid_all_actions }
  end

  context 'with admins' do
    let(:current_user) { create(:user, admin: true) }

    it { is_expected.to permit_only_actions(%i[index]) }
  end
end
