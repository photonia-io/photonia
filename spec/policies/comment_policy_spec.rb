# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentPolicy do
  include_context 'with auth actors'

  let(:photo) { create(:photo, user: owner) }
  let(:comment) { create(:comment, commentable: photo, user: author) }
  let(:author) { create(:user) }

  describe '#create?' do
    subject { described_class.new(current_user, Comment.new(commentable: photo)) }

    context 'when signed out' do
      let(:current_user) { nil }

      it { is_expected.not_to permit_action(:create) }
    end

    context 'when signed in' do
      let(:current_user) { create(:user) }

      it { is_expected.to permit_action(:create) }
    end

    context 'when the user is disabled' do
      let(:current_user) { create(:user, disabled: true) }

      it { is_expected.not_to permit_action(:create) }
    end

    context 'when commenting is disabled globally' do
      let(:current_user) { create(:user) }

      before { Setting.commenting_enabled = false }

      it { is_expected.not_to permit_action(:create) }
    end

    context 'when photo commenting is disabled' do
      let(:current_user) { create(:user) }

      before { Setting.photo_commenting_enabled = false }

      it { is_expected.not_to permit_action(:create) }
    end

    context 'on an album' do
      subject { described_class.new(current_user, Comment.new(commentable: album)) }

      let(:album) { create(:album) }
      let(:current_user) { create(:user) }

      it 'denies by default (album commenting is off until refined)' do
        is_expected.not_to permit_action(:create)
      end

      context 'when album commenting is enabled' do
        before { Setting.album_commenting_enabled = true }

        it { is_expected.to permit_action(:create) }
      end

      context 'when album commenting is enabled but the general switch is off' do
        before do
          Setting.album_commenting_enabled = true
          Setting.commenting_enabled = false
        end

        it 'still denies - the general switch wins' do
          is_expected.not_to permit_action(:create)
        end
      end
    end

    context 'when the commentable is a private photo the user cannot see' do
      let(:photo) { create(:photo, privacy: :private) }
      let(:current_user) { create(:user) }

      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe '#update?' do
    subject { described_class.new(current_user, comment) }

    context 'when the author is signed in' do
      let(:current_user) { author }

      it { is_expected.to permit_action(:update) }
    end

    context 'when a stranger is signed in' do
      let(:current_user) { stranger }

      it { is_expected.not_to permit_action(:update) }
    end

    context 'when the commentable owner is signed in' do
      let(:current_user) { owner }

      it 'does not allow the owner to edit someone else\'s comment' do
        is_expected.not_to permit_action(:update)
      end
    end

    context 'when an admin is signed in' do
      let(:current_user) { admin }

      it 'does not allow an admin to edit someone else\'s comment' do
        is_expected.not_to permit_action(:update)
      end
    end

    context 'when signed out' do
      let(:current_user) { nil }

      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe '#destroy?' do
    subject { described_class.new(current_user, comment) }

    context 'when the author is signed in' do
      let(:current_user) { author }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when the commentable owner is signed in' do
      let(:current_user) { owner }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when an admin is signed in' do
      let(:current_user) { admin }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when a stranger is signed in' do
      let(:current_user) { stranger }

      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'when signed out' do
      let(:current_user) { nil }

      it { is_expected.not_to permit_action(:destroy) }
    end
  end
end
