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
      allow(photo).to receive(:set_fields)
      photo.valid?
      expect(photo).to have_received(:set_fields)
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
      let(:photo_with_exif) { build_stubbed(:photo, image: File.open('spec/support/images/zell-am-see-with-exif.jpg')) }
      let(:photo_without_exif) { build_stubbed(:photo, image: File.open('spec/support/images/zell-am-see-without-exif.jpg')) }

      it 'returns exif data when the file has EXIF data' do
        exif_data = photo_with_exif.exif_from_file
        expect(exif_data).to be_present
        expect(exif_data.image_width).to eq 1620
      end

      it 'returns nil when the file has no EXIF data' do
        expect(photo_without_exif.exif_from_file).to be_nil
      end
    end

    describe '#exif' do
      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }
      let(:photo_with_nil_exif) { build_stubbed(:photo, exif: nil) }
      let(:photo_with_exif) { build_stubbed(:photo, exif: exif_data.to_json) }

      before do
        allow(photo_with_nil_exif).to receive(:save)
      end

      it 'calls #exif_from_file and #save when exif field is nil' do
        allow(photo_with_nil_exif).to receive(:exif_from_file)
        photo_with_nil_exif.exif
        expect(photo_with_nil_exif).to have_received(:exif_from_file)
        expect(photo_with_nil_exif).to have_received(:save)
      end

      it 'sets and returns exif data when #exif_from_file returns data' do
        allow(photo_with_nil_exif).to receive(:exif_from_file).and_return(exif_data)

        expect { photo_with_nil_exif.exif }.to change { photo_with_nil_exif.read_attribute(:exif) }.from(nil).to(exif_data.to_json)
        expect(photo_with_nil_exif.exif).to eq(exif_data)
      end

      it 'sets and returns error hash when #exif_from_file returns nil' do
        allow(photo_with_nil_exif).to receive(:exif_from_file).and_return(nil)

        expect { photo_with_nil_exif.exif }.to change { photo_with_nil_exif.read_attribute(:exif) }.from(nil).to(error_hash.to_json)
        expect(photo_with_nil_exif.exif).to eq(error_hash)
      end

      it 'does not call #exif_from_file or #save when exif field is already set' do
        allow(photo_with_exif).to receive(:exif_from_file)
        allow(photo_with_exif).to receive(:save)
        photo_with_exif.exif
        expect(photo_with_exif).not_to have_received(:exif_from_file)
        expect(photo_with_exif).not_to have_received(:save)
      end

      it 'returns the existing exif data when already set' do
        expect(photo_with_exif.exif).to eq(exif_data)
      end
    end

    describe '#exif_exists?' do
      let(:photo) { build_stubbed(:photo) }
      let(:exif_data) { { 'test' => 'test'.dup } } # .dup so we don't get a frozen string error
      let(:error_hash) { { 'error' => 'EXIF Not Readable' } }

      it 'returns true when #exif returns valid data' do
        allow(photo).to receive(:exif).and_return(exif_data)
        expect(photo.exif_exists?).to be true
      end

      it 'returns false when #exif returns an error hash' do
        allow(photo).to receive(:exif).and_return(error_hash)
        expect(photo.exif_exists?).to be false
      end
    end

    describe '#populate_exif_fields' do
      let(:timezone) { 'Bucharest' }
      let(:user) { create(:user, timezone: timezone) }
      let(:photo_with_exif) { create(:photo, user: user, timezone: user.timezone, image: File.open('spec/support/images/zell-am-see-with-exif.jpg')) }
      let(:photo_without_exif) { create(:photo, user: user, timezone: user.timezone, image: File.open('spec/support/images/zell-am-see-without-exif.jpg')) }

      it 'sets taken_at from the exif data when the file has EXIF data' do
        Time.use_zone(timezone) do
          expect { photo_with_exif.populate_exif_fields }.to change(photo_with_exif, :taken_at).from(nil).to(Time.zone.parse('2014-08-31 17:25:34'))
        end
      end

      it 'sets taken_at to the current time when the file has no EXIF data' do
        Timecop.freeze do
          expect { photo_without_exif.populate_exif_fields }.to change(photo_without_exif, :taken_at).from(nil).to(Time.zone.now)
        end
      end
    end

    describe '#add_derivatives' do
      let(:photo) { build_stubbed(:photo) }
      let(:image_attacher) { instance_double(Shrine::Attacher) }

      # We could do instance_double(ImageProcessing::MiniMagick::Processor) below,
      # but since ImageProcessing has a complex chainable API it would then fail
      # saying that resize_to_fill! is not defined on the double. That's because
      # bang methods are defined via method_missing in ImageProcessing::Chainable
      # https://github.com/janko/image_processing/blob/master/lib/image_processing/chainable.rb#L84

      # rubocop:disable RSpec/VerifiedDoubles
      let(:mock_image_processing) { double('ImageProcessing::MiniMagick') }
      # rubocop:enable RSpec/VerifiedDoubles

      let(:medium_side) { 800 }
      let(:thumbnail_side) { 300 }
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
        allow(photo).to receive(:image_attacher).and_return(image_attacher)
        allow(ENV).to receive(:fetch).with('PHOTONIA_MEDIUM_SIDE', nil).and_return(medium_side)
        allow(ENV).to receive(:fetch).with('PHOTONIA_THUMBNAIL_SIDE', nil).and_return(thumbnail_side)
        allow(ImageProcessing::MiniMagick).to receive(:source).and_return(mock_image_processing)
        allow(image_attacher).to receive(:file).and_return(instance_double(Shrine::UploadedFile, download: 'image_data'))
        allow(mock_image_processing).to receive_messages(crop: mock_image_processing, resize_to_fill!: 'processed_image')
      end

      it 'adds intelligent derivatives when intelligent_thumbnail is present' do
        allow(photo).to receive(:intelligent_thumbnail).and_return(intelligent_thumbnail)
        allow(photo).to receive(:custom_crop).with(intelligent_thumbnail, 'image_data').and_return(mock_image_processing)
        allow(image_attacher).to receive(:add_derivative)
        allow(image_attacher).to receive(:atomic_promote)

        photo.add_derivatives

        expect(photo).to have_received(:custom_crop).with(intelligent_thumbnail, 'image_data')
        expect(image_attacher).to have_received(:add_derivative).with(:medium_intelligent, 'processed_image')
        expect(image_attacher).to have_received(:add_derivative).with(:thumbnail_intelligent, 'processed_image')
        expect(image_attacher).to have_received(:atomic_promote)
      end

      it 'adds user derivatives when user_thumbnail is present' do
        allow(photo).to receive_messages(intelligent_thumbnail: nil, user_thumbnail: user_thumbnail)
        allow(photo).to receive(:custom_crop).with(user_thumbnail, 'image_data').and_return(mock_image_processing)
        allow(image_attacher).to receive(:add_derivative)
        allow(image_attacher).to receive(:atomic_promote)

        photo.add_derivatives

        expect(photo).to have_received(:custom_crop).with(user_thumbnail, 'image_data')
        expect(image_attacher).to have_received(:add_derivative).with(:medium_user, 'processed_image')
        expect(image_attacher).to have_received(:add_derivative).with(:thumbnail_user, 'processed_image')
        expect(image_attacher).to have_received(:atomic_promote)
      end

      it 'adds all four derivatives when both thumbnails are present' do
        allow(photo).to receive_messages(intelligent_thumbnail: intelligent_thumbnail, user_thumbnail: user_thumbnail)
        allow(photo).to receive(:custom_crop).with(intelligent_thumbnail, 'image_data').and_return(mock_image_processing)
        allow(photo).to receive(:custom_crop).with(user_thumbnail, 'image_data').and_return(mock_image_processing)
        allow(image_attacher).to receive(:add_derivative)
        allow(image_attacher).to receive(:atomic_promote)

        photo.add_derivatives

        expect(photo).to have_received(:custom_crop).with(intelligent_thumbnail, 'image_data')
        expect(photo).to have_received(:custom_crop).with(user_thumbnail, 'image_data')
        expect(image_attacher).to have_received(:add_derivative).with(:medium_intelligent, 'processed_image')
        expect(image_attacher).to have_received(:add_derivative).with(:thumbnail_intelligent, 'processed_image')
        expect(image_attacher).to have_received(:add_derivative).with(:medium_user, 'processed_image')
        expect(image_attacher).to have_received(:add_derivative).with(:thumbnail_user, 'processed_image')
        expect(image_attacher).to have_received(:atomic_promote)
      end

      it 'does not add any derivatives when no thumbnails are present' do
        allow(photo).to receive_messages(intelligent_thumbnail: nil, user_thumbnail: nil)
        allow(image_attacher).to receive(:add_derivative)
        allow(image_attacher).to receive(:atomic_promote)

        photo.add_derivatives

        expect(image_attacher).not_to have_received(:add_derivative)
        expect(image_attacher).not_to have_received(:atomic_promote)
      end
    end

    describe '#custom_crop' do
      let(:photo) { build_stubbed(:photo) }
      let(:image_attacher) { instance_double(Shrine::Attacher) }
      # See the comment in the #add_derivatives spec for why we don't use instance_double here
      # rubocop:disable RSpec/VerifiedDoubles
      let(:mock_image_processing) { double('ImageProcessing::MiniMagick') }
      # rubocop:enable RSpec/VerifiedDoubles
      let(:pixel_width) { 1600 }
      let(:pixel_height) { 1200 }
      let(:thumbnail) do
        {
          top: 0.25,
          left: 0.125,
          width: 0.5,
          height: 0.666667
        }
      end

      before do
        allow(photo).to receive_messages(image_attacher: image_attacher, pixel_width: pixel_width, pixel_height: pixel_height)
        allow(image_attacher).to receive(:file).and_return(instance_double(Shrine::UploadedFile, download: 'image_data'))
        allow(ImageProcessing::MiniMagick).to receive(:source).and_return(mock_image_processing)
        allow(mock_image_processing).to receive(:crop).and_return('cropped_image')
      end

      it 'calls ImageProcessing::MiniMagick.source with the downloaded image' do
        photo.send(:custom_crop, thumbnail)
        expect(ImageProcessing::MiniMagick).to have_received(:source).with('image_data')
      end

      it 'computes pixel coordinates from percentages and calls crop with square size' do
        photo.send(:custom_crop, thumbnail)
        # Expected: x=200 (1600*0.125), y=300 (1200*0.25), square_size=800 (min of 1600*0.5=800, 1200*0.666667=800)
        expect(mock_image_processing).to have_received(:crop).with(200, 300, 800, 800)
      end

      it 'handles string keys from JSONB (user_thumbnail)' do
        string_key_thumbnail = {
          'top' => 0.125,
          'left' => 0.125,
          'width' => 0.25,
          'height' => 0.333333
        }
        photo.send(:custom_crop, string_key_thumbnail)
        # Expected: x=200 (1600*0.125), y=150 (1200*0.125), square_size=399 (min of 1600*0.25=400, 1200*0.333333=399.9996→399)
        expect(mock_image_processing).to have_received(:crop).with(200, 150, 399, 399)
      end

      it 'returns the cropped image' do
        result = photo.send(:custom_crop, thumbnail)
        expect(result).to eq('cropped_image')
      end

      it 'uses the smaller dimension to ensure square crop' do
        # Width percentage produces smaller pixel size
        asymmetric_thumbnail = {
          top: 0.0,
          left: 0.0,
          width: 0.5,   # 1600 * 0.5 = 800px
          height: 0.8   # 1200 * 0.8 = 960px
        }
        photo.send(:custom_crop, asymmetric_thumbnail)
        # Should use 800x800 (smaller of the two)
        expect(mock_image_processing).to have_received(:crop).with(0, 0, 800, 800)
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
