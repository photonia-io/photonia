# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :text
#  exif                     :jsonb
#  flickr_faves             :integer
#  flickr_impressions_count :integer          default(0), not null
#  flickr_json              :jsonb
#  flickr_original          :string
#  flickr_photopage         :string
#  image_data               :jsonb
#  impressions_count        :integer          default(0), not null
#  license                  :string
#  posted_at                :datetime
#  privacy                  :enum             default("public")
#  rekognition_response     :jsonb
#  serial_number            :bigint           not null
#  slug                     :string
#  taken_at                 :datetime
#  taken_at_from_exif       :boolean          default(FALSE)
#  timezone                 :string           default("UTC"), not null
#  title                    :string
#  tsv                      :tsvector
#  user_thumbnail           :jsonb
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
    context 'when there is no title and no description' do
      let(:photo) { build(:photo, title: nil, description: nil) }

      it 'is not valid' do
        expect(photo).not_to be_valid
      end
    end

    context 'when there is a title and no description' do
      let(:photo) { build(:photo, description: nil) }

      it 'is valid' do
        expect(photo).to be_valid
      end
    end

    context 'when there is no title and a description' do
      let(:photo) { build(:photo, title: nil) }

      it 'is valid' do
        expect(photo).to be_valid
      end
    end
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
      subject { photo.exif_from_file }

      let(:photo) { build_stubbed(:photo, image: File.open(filename)) }

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
      subject { photo.exif }

      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }

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
      subject { photo.exif_exists? }

      let(:photo) { build_stubbed(:photo) }
      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }

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

    describe '#add_derivatives' do
      let(:photo) { build_stubbed(:photo) }
      let(:image_attacher) { double('image_attacher') }
      let(:mock_image_processing) { double('ImageProcessing::MiniMagick') }
      let(:medium_side) { 800 }
      let(:thumbnail_side) { 300 }

      before do
        allow(photo).to receive(:image_attacher).and_return(image_attacher)
        allow(ENV).to receive(:fetch).with('PHOTONIA_MEDIUM_SIDE', nil).and_return(medium_side)
        allow(ENV).to receive(:fetch).with('PHOTONIA_THUMBNAIL_SIDE', nil).and_return(thumbnail_side)
        allow(ImageProcessing::MiniMagick).to receive(:source).and_return(mock_image_processing)
      end

      context 'when intelligent_thumbnail is present' do
        let(:intelligent_thumbnail) do
          {
            x: 100,
            y: 100,
            pixel_width: 400,
            pixel_height: 400,
            top: 0.25,
            left: 0.25,
            width: 0.5,
            height: 0.5
          }
        end

        before do
          allow(photo).to receive(:intelligent_thumbnail).and_return(intelligent_thumbnail)
          allow(image_attacher).to receive(:file).and_return(double('file', download: 'image_data'))
          allow(mock_image_processing).to receive_messages(crop: mock_image_processing, resize_to_fill!: 'processed_image')
        end

        it 'adds medium_intelligent derivative' do
          expect(photo).to receive(:custom_crop).with(intelligent_thumbnail).twice.and_return(mock_image_processing)
          expect(mock_image_processing).to receive(:resize_to_fill!).with(medium_side, medium_side).and_return('processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:medium_intelligent, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_intelligent, 'processed_image')
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'adds thumbnail_intelligent derivative' do
          expect(photo).to receive(:custom_crop).with(intelligent_thumbnail).twice.and_return(mock_image_processing)
          expect(mock_image_processing).to receive(:resize_to_fill!).with(thumbnail_side, thumbnail_side).and_return('processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:medium_intelligent, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_intelligent, 'processed_image')
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'calls custom_crop with intelligent_thumbnail' do
          expect(photo).to receive(:custom_crop).with(intelligent_thumbnail).twice.and_return(mock_image_processing)
          allow(mock_image_processing).to receive(:resize_to_fill!).and_return('processed_image')
          allow(image_attacher).to receive(:add_derivative)
          allow(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'calls atomic_promote' do
          allow(photo).to receive(:custom_crop).twice.and_return(mock_image_processing)
          allow(mock_image_processing).to receive(:resize_to_fill!).and_return('processed_image')
          allow(image_attacher).to receive(:add_derivative)
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end
      end

      context 'when user_thumbnail is present' do
        let(:user_thumbnail) do
          {
            'x' => 50,
            'y' => 50,
            'pixel_width' => 200,
            'pixel_height' => 200,
            'top' => 0.125,
            'left' => 0.125,
            'width' => 0.25,
            'height' => 0.25
          }
        end

        before do
          allow(photo).to receive_messages(intelligent_thumbnail: nil, user_thumbnail: user_thumbnail)
          allow(image_attacher).to receive(:file).and_return(double('file', download: 'image_data'))
          allow(mock_image_processing).to receive_messages(crop: mock_image_processing, resize_to_fill!: 'processed_image')
        end

        it 'adds medium_user derivative' do
          expect(photo).to receive(:custom_crop).with(user_thumbnail).twice.and_return(mock_image_processing)
          expect(mock_image_processing).to receive(:resize_to_fill!).with(medium_side, medium_side).and_return('processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:medium_user, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_user, 'processed_image')
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'adds thumbnail_user derivative' do
          expect(photo).to receive(:custom_crop).with(user_thumbnail).twice.and_return(mock_image_processing)
          expect(mock_image_processing).to receive(:resize_to_fill!).with(thumbnail_side, thumbnail_side).and_return('processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:medium_user, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_user, 'processed_image')
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'calls custom_crop with user_thumbnail' do
          expect(photo).to receive(:custom_crop).with(user_thumbnail).twice.and_return(mock_image_processing)
          allow(mock_image_processing).to receive(:resize_to_fill!).and_return('processed_image')
          allow(image_attacher).to receive(:add_derivative)
          allow(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end

        it 'calls atomic_promote' do
          allow(photo).to receive(:custom_crop).twice.and_return(mock_image_processing)
          allow(mock_image_processing).to receive(:resize_to_fill!).and_return('processed_image')
          allow(image_attacher).to receive(:add_derivative)
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end
      end

      context 'when both intelligent_thumbnail and user_thumbnail are present' do
        let(:intelligent_thumbnail) { { x: 100, y: 100, pixel_width: 400, pixel_height: 400 } }
        let(:user_thumbnail) { { 'x' => 50, 'y' => 50, 'pixel_width' => 200, 'pixel_height' => 200 } }

        before do
          allow(photo).to receive_messages(intelligent_thumbnail: intelligent_thumbnail, user_thumbnail: user_thumbnail)
          allow(image_attacher).to receive(:file).and_return(double('file', download: 'image_data'))
          allow(mock_image_processing).to receive_messages(crop: mock_image_processing, resize_to_fill!: 'processed_image')
        end

        it 'adds all four derivatives' do
          expect(photo).to receive(:custom_crop).with(intelligent_thumbnail).twice.and_return(mock_image_processing)
          expect(photo).to receive(:custom_crop).with(user_thumbnail).twice.and_return(mock_image_processing)
          expect(image_attacher).to receive(:add_derivative).with(:medium_intelligent, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_intelligent, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:medium_user, 'processed_image')
          expect(image_attacher).to receive(:add_derivative).with(:thumbnail_user, 'processed_image')
          expect(image_attacher).to receive(:atomic_promote)
          photo.add_derivatives
        end
      end

      context 'when neither intelligent_thumbnail nor user_thumbnail is present' do
        before do
          allow(photo).to receive_messages(intelligent_thumbnail: nil, user_thumbnail: nil)
        end

        it 'does not add any derivatives' do
          expect(image_attacher).not_to receive(:add_derivative)
          expect(image_attacher).not_to receive(:atomic_promote)
          photo.add_derivatives
        end
      end
    end

    describe '#custom_crop' do
      let(:photo) { build_stubbed(:photo) }
      let(:image_attacher) { double('image_attacher') }
      let(:mock_image_processing) { double('ImageProcessing::MiniMagick') }
      let(:thumbnail) do
        {
          x: 100,
          y: 100,
          pixel_width: 400,
          pixel_height: 400
        }
      end

      before do
        allow(photo).to receive(:image_attacher).and_return(image_attacher)
        allow(image_attacher).to receive(:file).and_return(double('file', download: 'image_data'))
        allow(ImageProcessing::MiniMagick).to receive(:source).and_return(mock_image_processing)
        allow(mock_image_processing).to receive(:crop).and_return('cropped_image')
      end

      it 'calls ImageProcessing::MiniMagick.source with the downloaded image' do
        expect(ImageProcessing::MiniMagick).to receive(:source).with('image_data')
        photo.send(:custom_crop, thumbnail)
      end

      it 'calls crop with the correct parameters' do
        expect(mock_image_processing).to receive(:crop).with(100, 100, 400, 400)
        photo.send(:custom_crop, thumbnail)
      end

      it 'handles string keys from JSONB' do
        string_key_thumbnail = {
          'x' => 50,
          'y' => 50,
          'pixel_width' => 200,
          'pixel_height' => 200
        }
        expect(mock_image_processing).to receive(:crop).with(50, 50, 200, 200)
        photo.send(:custom_crop, string_key_thumbnail)
      end

      it 'returns the cropped image' do
        result = photo.send(:custom_crop, thumbnail)
        expect(result).to eq('cropped_image')
      end
    end
  end

  describe 'serial number setting' do
    it 'sets the serial number before validation' do
      photo = build(:photo)
      photo.valid?
      expect(photo.serial_number).not_to be_blank
    end

    it 'generates a serial number if it is not set' do
      photo = build(:photo, serial_number: nil)
      expect { photo.valid? }.to change(photo, :serial_number).from(nil)
    end

    it 'does not overwrite the serial number if it is already set' do
      photo = build(:photo, serial_number: 123)
      photo.valid?
      expect(photo.serial_number).to eq(123)
    end
  end

  it_behaves_like 'it has trackable title and description', model: :photo
end
