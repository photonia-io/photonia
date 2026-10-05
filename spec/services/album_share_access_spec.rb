# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlbumShareAccess do
  describe '.resolve' do
    it 'returns nil when the slug is blank' do
      expect(described_class.resolve(nil, 'token')).to be_nil
    end

    it 'returns nil when the token is blank' do
      album = create(:album, share_mode: 'all_photos').tap(&:regenerate_share_token!)
      expect(described_class.resolve(album.slug, nil)).to be_nil
    end

    it 'returns nil for an unknown album slug' do
      expect(described_class.resolve('does-not-exist', 'token')).to be_nil
    end

    it 'returns nil when the token does not match' do
      album = create(:album, share_mode: 'all_photos').tap(&:regenerate_share_token!)
      expect(described_class.resolve(album.slug, 'wrong-token')).to be_nil
    end

    it 'returns nil when share_mode is off' do
      album = create(:album, share_mode: 'off').tap(&:regenerate_share_token!)
      expect(described_class.resolve(album.slug, album.share_token)).to be_nil
    end

    it 'returns an access instance for a matching, non-private album and token' do
      album = create(:album, privacy: 'private', share_mode: 'public_photos').tap(&:regenerate_share_token!)

      access = described_class.resolve(album.slug, album.share_token)

      expect(access).to be_a(described_class)
      expect(access.album).to eq(album)
    end
  end

  describe '#covers_album?' do
    let(:album) { create(:album, share_mode: 'public_photos').tap(&:regenerate_share_token!) }
    let(:access) { described_class.new(album) }

    it 'is true for the same album' do
      expect(access.covers_album?(album)).to be(true)
    end

    it 'is false for a different album' do
      expect(access.covers_album?(create(:album))).to be(false)
    end
  end

  describe '#all_photos? and #covers_photo?' do
    let(:album) { create(:album, sorting_type: 'manual') }
    let(:public_photo) { create(:photo, privacy: 'public') }
    let(:private_photo) { create(:photo, privacy: 'private') }
    let(:outside_photo) { create(:photo, privacy: 'public') }

    before do
      album.photos << [public_photo, private_photo]
      album.maintenance
    end

    context 'when share_mode is public_photos' do
      let(:access) { described_class.new(album.tap { |a| a.update_columns(share_mode: 'public_photos') }) } # rubocop:disable Rails/SkipsModelValidations

      it 'is not all_photos' do
        expect(access.all_photos?).to be(false)
      end

      it 'covers the public photo in the album' do
        expect(access.covers_photo?(public_photo)).to be(true)
      end

      it 'does not cover the private photo in the album' do
        expect(access.covers_photo?(private_photo)).to be(false)
      end

      it 'does not cover a photo outside the album' do
        expect(access.covers_photo?(outside_photo)).to be(false)
      end
    end

    context 'when share_mode is all_photos' do
      let(:access) { described_class.new(album.tap { |a| a.update_columns(share_mode: 'all_photos') }) } # rubocop:disable Rails/SkipsModelValidations

      it 'is all_photos' do
        expect(access.all_photos?).to be(true)
      end

      it 'covers the private photo in the album' do
        expect(access.covers_photo?(private_photo)).to be(true)
      end

      it 'does not cover a photo outside the album' do
        expect(access.covers_photo?(outside_photo)).to be(false)
      end

      it '#photo_scope returns every photo in the album regardless of privacy' do
        expect(access.photo_scope).to contain_exactly(public_photo, private_photo)
      end
    end
  end
end
