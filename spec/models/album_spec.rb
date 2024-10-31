# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  photos_count             :integer          default(0), not null
#  privacy                  :enum             default("public")
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

      context 'when the album has no photos' do
        before do
          album.maintenance
        end

        it 'sets the photos_count to 0' do
          expect(album.photos_count).to eq(0)
        end

        it 'sets the public_photos_count to 0' do
          expect(album.public_photos_count).to eq(0)
        end

        it 'sets the public_cover_photo_id to nil' do
          expect(album.public_cover_photo_id).to be_nil
        end
      end

      context 'when the album has no public photos' do
        before do
          album.photos << create(:photo, privacy: 'private')
          album.maintenance
        end

        it 'sets the photos_count to 1' do
          expect(album.photos_count).to eq(1)
        end

        it 'sets the public_photos_count to 0' do
          expect(album.public_photos_count).to eq(0)
        end

        it 'sets the public_cover_photo_id to nil' do
          expect(album.public_cover_photo_id).to be_nil
        end
      end

      context 'when the album has only public photos' do
        before do
          album.photos << create_list(:photo, 2, privacy: 'public')
          album.maintenance
        end

        it 'sets the photos_count to 2' do
          expect(album.photos_count).to eq(2)
        end

        it 'sets the public_photos_count to 2' do
          expect(album.public_photos_count).to eq(2)
        end

        it 'sets the public_cover_photo_id to the first public photo' do
          expect(album.public_cover_photo_id).to eq(album.photos.first.id)
        end
      end
    end
  end

  describe 'serial number setting' do
    it 'sets the serial number before validation' do
      album = build(:album)
      album.valid?
      expect(album.serial_number).not_to be_blank
    end

    it 'generates a serial number if it is not set' do
      album = build(:album, serial_number: nil)
      expect { album.valid? }.to change(album, :serial_number).from(nil)
    end

    it 'does not overwrite the serial number if it is already set' do
      album = build(:album, serial_number: 123)
      album.valid?
      expect(album.serial_number).to eq(123)
    end
  end
end
