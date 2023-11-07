# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                       :bigint           not null, primary key
#  description              :text
#  exif                     :jsonb
#  flickr_faves             :integer
#  flickr_impressions_count :integer          default(0), not null
#  flickr_json              :jsonb
#  flickr_original          :string
#  flickr_photopage         :string
#  image_data               :jsonb
#  impressions_count        :integer          default(0), not null
#  license                  :string
#  name                     :string
#  posted_at                :datetime
#  privacy                  :enum             default("public")
#  rekognition_response     :jsonb
#  serial_number            :bigint           not null
#  slug                     :string
#  taken_at                 :datetime
#  taken_at_from_exif       :boolean          default(FALSE)
#  timezone                 :string           default("UTC"), not null
#  tsv                      :tsvector
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint
#
# Indexes
#
#  index_photos_on_exif                  (exif) USING gin
#  index_photos_on_rekognition_response  (rekognition_response) USING gin
#  index_photos_on_slug                  (slug) UNIQUE
#  index_photos_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Photo do
  it 'has a valid factory' do
    expect(build(:photo)).to be_valid
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many albums' do
      association = described_class.reflect_on_association(:albums)
      expect(association.macro).to eq :has_many
    end

    it 'has many albums through albums_photos' do
      association = described_class.reflect_on_association(:albums)
      expect(association.options[:through]).to eq :albums_photos
    end

    it 'has many labels' do
      association = described_class.reflect_on_association(:labels)
      expect(association.macro).to eq :has_many
    end
  end

  describe 'callbacks' do
    it 'calls set_fields before validation' do
      photo = build(:photo)
      expect(photo).to receive(:set_fields)
      photo.valid?
    end
  end

  describe 'instance methods' do
    describe '#next' do
      it 'returns the next photo' do
        photo = create(:photo)
        next_photo = create(:photo, posted_at: photo.posted_at + 1.day)
        expect(photo.next).to eq(next_photo)
      end
    end

    describe '#prev' do
      it 'returns the previous photo' do
        photo = create(:photo)
        prev_photo = create(:photo, posted_at: photo.posted_at - 1.day)
        expect(photo.prev).to eq(prev_photo)
      end
    end

    describe '#exif_from_file' do
      let(:photo) { build_stubbed(:photo, image: File.open(filename)) }

      subject { photo.exif_from_file }

      context 'when the file has EXIF data' do
        let(:filename) { 'spec/support/images/zell-am-see-with-exif.jpg' }

        it 'returns some exif data from the file' do
          expect(subject).to be_present
        end

        it 'returns the correct image width from the exif data' do
          expect(subject.image_width).to eq 1620
        end
      end

      context 'when the file has no EXIF data' do
        let(:filename) { 'spec/support/images/zell-am-see-without-exif.jpg' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    describe '#exif' do
      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }

      subject { photo.exif }

      context 'when the exif field is nil in the beginning' do
        let(:photo) { build_stubbed(:photo, exif: nil) }

        before do
          allow(photo).to receive(:exif_from_file).and_return(exif_data)
          allow(photo).to receive(:save)
        end

        it 'calls #exif_from_file' do
          expect(photo).to receive(:exif_from_file)
          subject
        end

        it 'calls #save' do
          expect(photo).to receive(:save)
          subject
        end

        context 'when #exif_from_file returns some exif data' do
          it 'sets the field to the exif data' do
            expect { subject }.to change { photo.read_attribute(:exif) }.from(nil).to(exif_data.to_json)
          end

          it 'returns the exif data' do
            expect(subject).to eq(exif_data)
          end
        end

        context 'when #exif_from_file returns nil' do
          before do
            allow(photo).to receive(:exif_from_file).and_return(nil)
          end

          it 'sets the field to an error hash' do
            expect { subject }.to change { photo.read_attribute(:exif) }.from(nil).to(error_hash.to_json)
          end

          it 'returns the error hash' do
            expect(subject).to eq(error_hash)
          end
        end
      end

      context 'when the exif field has already been set' do
        let(:photo) { build_stubbed(:photo, exif: exif_data.to_json) }

        it 'does not call #exif_from_file' do
          expect(photo).not_to receive(:exif_from_file)
          subject
        end

        it 'does not call #save' do
          expect(photo).not_to receive(:save)
          subject
        end

        it 'returns the exif data' do
          expect(subject).to eq(exif_data)
        end
      end
    end

    describe '#exif_exists?' do
      let(:photo) { build_stubbed(:photo) }
      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }

      subject { photo.exif_exists? }

      context 'when #exif returns some exif data' do
        before do
          allow(photo).to receive(:exif).and_return(exif_data)
        end

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'when #exif returns an error hash' do
        before do
          allow(photo).to receive(:exif).and_return(error_hash)
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end

    describe '#populate_exif_fields' do
      subject(:populate_exif_fields) { photo.populate_exif_fields }

      let(:timezone) { 'Bucharest' }
      let(:user) { create(:user, timezone: timezone) }
      let(:photo) { create(:photo, user: user, timezone: user.timezone, image: File.open(filename)) }

      context 'when the file has EXIF data' do
        let(:filename) { 'spec/support/images/zell-am-see-with-exif.jpg' }

        it 'sets taken_at from the exif data' do
          Time.use_zone(timezone) do
            expect { populate_exif_fields }.to change(photo, :taken_at).from(nil).to(Time.zone.parse('2014-08-31 17:25:34'))
          end
        end
      end

      context 'when the file has no EXIF data' do
        let(:filename) { 'spec/support/images/zell-am-see-without-exif.jpg' }

        before do
          Timecop.freeze
        end

        after do
          Timecop.return
        end

        it 'sets taken_at to the current time' do
          expect { populate_exif_fields }.to change(photo, :taken_at).from(nil).to(Time.zone.now)
        end
      end
    end
  end
end
