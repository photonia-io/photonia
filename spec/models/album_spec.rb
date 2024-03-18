# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  photos_count             :integer          default(0), not null
#  public_photos_count      :integer          default(0), not null
#  serial_number            :bigint
#  slug                     :string
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  public_cover_photo_id    :bigint
#  user_cover_photo_id      :bigint
#  user_id                  :bigint           default(1), not null
#
# Indexes
#
#  index_albums_on_public_cover_photo_id  (public_cover_photo_id)
#  index_albums_on_user_cover_photo_id    (user_cover_photo_id)
#  index_albums_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Album do
  it 'has a valid factory' do
    expect(build(:album)).to be_valid
  end

  describe 'validations' do
    it 'is invalid without a title' do
      expect(build(:album, title: nil)).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many photos through albums_photos' do
      association = described_class.reflect_on_association(:photos)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :albums_photos
    end
  end

  describe 'callbacks' do
    it 'calls set_serial_number after create' do
      album = build(:album)
      expect(album).to receive(:set_serial_number)
      album.save
    end
  end

  describe 'instance methods' do
    describe '#slug' do
      it 'returns the correct slug' do
        album = create(:album)
        expect(album.slug).to eq(album.serial_number.to_s)
      end
    end

    describe '#maintenance' do
      let(:album) { create(:album) }

      context '5 total photos, 4 belong to the album of which 3 are public' do
        let(:public_photo) { create(:photo, privacy: 'public') }
        let(:private_photo) { create(:photo, privacy: 'private') }
        let(:public_photos) { create_list(:photo, 2, privacy: 'public') }
        let(:the_other_photo) { create(:photo) }

        before do
          album.photos << public_photo
          album.photos << private_photo
          album.photos << public_photos
          album.maintenance
        end

        it 'updates the photos_count' do
          expect(album.photos_count).to eq(4)
        end

        it 'updates the public_photos_count' do
          expect(album.public_photos_count).to eq(3)
        end

        it 'sets the public_cover_photo_id to the first public photo' do
          expect(album.public_cover_photo_id).to eq(public_photo.id)
        end

        context 'when the user_cover_photo is public' do
          before do
            album.update(user_cover_photo_id: public_photos.last.id)
            album.maintenance
          end

          it 'sets the public_cover_photo_id to the user_cover_photo_id' do
            expect(album.public_cover_photo_id).to eq(public_photos.last.id)
          end

          context 'but then the user_cover_photo is deleted' do
            before do
              public_photos.last.destroy
              album.maintenance
            end

            it 'sets the public_cover_photo_id to the first public photo' do
              expect(album.public_cover_photo_id).to eq(public_photo.id)
            end

            it 'sets the user_cover_photo_id to nil' do
              expect(album.user_cover_photo_id).to be_nil
            end
          end

          context 'but then the user_cover_photo is made private' do
            before do
              public_photos.last.update(privacy: 'private')
              album.maintenance
            end

            it 'sets the public_cover_photo_id to the first public photo' do
              expect(album.reload.public_cover_photo_id).to eq(public_photo.id)
            end

            it 'leaves the user_cover_photo_id as is' do
              expect(album.user_cover_photo_id).to eq(public_photos.last.id)
            end
          end
        end

        context 'when the user_cover_photo is private' do
          before do
            album.update(user_cover_photo_id: private_photo.id)
            album.maintenance
          end

          it 'sets the public_cover_photo_id to the first public photo' do
            expect(album.public_cover_photo_id).to eq(public_photo.id)
          end

          it 'leaves the user_cover_photo_id as is' do
            expect(album.user_cover_photo_id).to eq(private_photo.id)
          end

          context 'but then the user_cover_photo is deleted' do
            before do
              private_photo.destroy
              album.maintenance
            end

            it 'sets the public_cover_photo_id to the first public photo' do
              expect(album.public_cover_photo_id).to eq(public_photo.id)
            end

            it 'sets the user_cover_photo_id to nil' do
              expect(album.user_cover_photo_id).to be_nil
            end
          end

          context 'but then the user_cover_photo is made public' do
            before do
              private_photo.update(privacy: 'public')
              album.maintenance
            end

            it 'sets the public_cover_photo_id to the user_cover_photo_id' do
              expect(album.public_cover_photo_id).to eq(private_photo.id)
            end

            it 'leaves the user_cover_photo_id as is' do
              expect(album.user_cover_photo_id).to eq(private_photo.id)
            end
          end
        end
      end
    end
  end
end
