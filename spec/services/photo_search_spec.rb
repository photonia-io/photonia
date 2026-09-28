# frozen_string_literal: true

require 'rails_helper'

describe PhotoSearch, type: :service do
  let(:flickr_tagging_source) { TaggingSource.find_by(name: 'Flickr') }
  let(:rekognition_tagging_source) { TaggingSource.find_by(name: 'Rekognition') }

  def search(sort: 'relevance', direction: 'desc', album_scope: Album.unscoped, **filters)
    described_class.new(Photo.unscoped, filters, sort:, direction:, album_scope:).relation
  end

  describe 'text query' do
    it 'filters by the pg_search text query' do
      match = create(:photo, title: 'Sunset over the lake')
      create(:photo, title: 'Forest trail')

      expect(search(query: 'lake')).to contain_exactly(match)
    end
  end

  describe 'tags' do
    it 'filters ANY-mode by at least one of the listed tags' do
      match = create(:photo)
      other = create(:photo)
      flickr_tagging_source.tag(match, with: 'sunset,lake', on: :tags)
      flickr_tagging_source.tag(other, with: 'forest', on: :tags)

      expect(search(tags: %w[sunset mountain], tags_mode: 'any')).to contain_exactly(match)
    end

    it 'filters ALL-mode requiring every listed tag' do
      match = create(:photo)
      partial = create(:photo)
      flickr_tagging_source.tag(match, with: 'sunset,lake', on: :tags)
      flickr_tagging_source.tag(partial, with: 'sunset', on: :tags)

      expect(search(tags: %w[sunset lake], tags_mode: 'all')).to contain_exactly(match)
    end

    it 'does not duplicate a photo carrying the same ALL-mode tag from two taggers' do
      photo = create(:photo)
      flickr_tagging_source.tag(photo, with: 'sunset', on: :tags)
      rekognition_tagging_source.tag(photo, with: 'sunset', on: :tags)

      expect(search(tags: %w[sunset], tags_mode: 'all').to_a).to eq([photo])
    end

    it 'excludes photos tagged with any of the exclude_tags' do
      excluded = create(:photo)
      keep = create(:photo)
      flickr_tagging_source.tag(excluded, with: 'private-event', on: :tags)
      flickr_tagging_source.tag(keep, with: 'sunset', on: :tags)

      expect(search(exclude_tags: %w[private-event])).to contain_exactly(keep)
    end
  end

  describe 'dates' do
    it 'filters by taken_at range' do
      in_range = create(:photo, taken_at: Time.zone.local(2020, 6, 1))
      create(:photo, taken_at: Time.zone.local(2019, 1, 1))

      result = search(taken_at_from: Date.new(2020, 1, 1), taken_at_to: Date.new(2020, 12, 31))
      expect(result).to contain_exactly(in_range)
    end

    it 'filters by posted_at range' do
      in_range = create(:photo, posted_at: Time.zone.local(2021, 3, 1))
      create(:photo, posted_at: Time.zone.local(2018, 1, 1))

      result = search(posted_at_from: Date.new(2021, 1, 1), posted_at_to: Date.new(2021, 12, 31))
      expect(result).to contain_exactly(in_range)
    end
  end

  describe 'camera' do
    it 'filters by camera make and model' do
      match = create(:photo, exif: { 'ifd0' => { 'make' => 'Canon', 'model' => 'EOS R5' } })
      create(:photo, exif: { 'ifd0' => { 'make' => 'Nikon', 'model' => 'Z6' } })

      expect(search(camera_make: 'Canon', camera_model: 'EOS R5')).to contain_exactly(match)
    end
  end

  describe 'numeric EXIF' do
    it 'filters by f_number range, parsing an "a/b" rational string' do
      match = create(:photo, exif: { 'exif' => { 'fnumber' => '14/5' } }) # 2.8
      create(:photo, exif: { 'exif' => { 'fnumber' => '8/1' } }) # 8.0

      expect(search(f_number_min: 2.0, f_number_max: 4.0)).to contain_exactly(match)
    end

    it 'filters by f_number range for a plain numeric legacy string' do
      match = create(:photo, exif: { 'exif' => { 'fnumber' => '2.8' } })

      expect(search(f_number_min: 2.0, f_number_max: 4.0)).to contain_exactly(match)
    end

    it 'filters by ISO range' do
      match = create(:photo, exif: { 'exif' => { 'iso_speed_ratings' => 400 } })
      create(:photo, exif: { 'exif' => { 'iso_speed_ratings' => 3200 } })

      expect(search(iso_min: 100, iso_max: 800)).to contain_exactly(match)
    end

    it 'filters by focal_length range' do
      match = create(:photo, exif: { 'exif' => { 'focal_length' => '70/1' } })
      create(:photo, exif: { 'exif' => { 'focal_length' => '200/1' } })

      expect(search(focal_length_min: 50.0, focal_length_max: 100.0)).to contain_exactly(match)
    end
  end

  describe 'labels' do
    it 'filters by label name and minimum confidence' do
      match = create(:photo)
      create(:label, photo: match, name: 'Dog', confidence: 90.0)
      low_confidence = create(:photo)
      create(:label, photo: low_confidence, name: 'Dog', confidence: 10.0)

      expect(search(labels: ['Dog'], label_min_confidence: 50.0)).to contain_exactly(match)
    end
  end

  describe 'license' do
    it 'filters by a known license value' do
      match = create(:photo, license: 'CC BY 4.0')
      create(:photo, license: 'CC0 1.0')

      expect(search(license: 'CC BY 4.0')).to contain_exactly(match)
    end

    it 'treats All Rights Reserved as matching a nil or blank license too' do
      explicit = create(:photo, license: License::ALL_RIGHTS_RESERVED)
      nil_license = create(:photo, license: nil)
      create(:photo, license: 'CC0 1.0')

      expect(search(license: License::ALL_RIGHTS_RESERVED)).to contain_exactly(explicit, nil_license)
    end

    it 'returns none for an unknown license' do
      create(:photo, license: 'CC0 1.0')

      expect(search(license: 'Not A License')).to be_empty
    end
  end

  describe 'album' do
    it 'filters by album slug' do
      album = create(:album)
      in_album = create(:photo)
      album.photos << in_album
      create(:photo)

      expect(search(album_id: album.slug)).to contain_exactly(in_album)
    end

    it 'returns none for an unknown album slug' do
      create(:photo)

      expect(search(album_id: 'does-not-exist')).to be_empty
    end

    it 'filters no_album to photos with no album membership' do
      album = create(:album)
      in_album = create(:photo)
      album.photos << in_album
      without_album = create(:photo)

      expect(search(no_album: true)).to contain_exactly(without_album)
    end
  end

  describe 'missing data' do
    it 'filters untagged photos' do
      tagged = create(:photo)
      flickr_tagging_source.tag(tagged, with: 'sunset', on: :tags)
      untagged = create(:photo)

      expect(search(untagged: true)).to contain_exactly(untagged)
    end

    it 'filters photos with no title' do
      create(:photo, title: 'Has a title')
      no_title = create(:photo, title: nil)

      expect(search(no_title: true)).to contain_exactly(no_title)
    end

    it 'filters photos with no description' do
      create(:photo, description: 'Has a description')
      no_description = create(:photo, description: nil)

      expect(search(no_description: true)).to contain_exactly(no_description)
    end

    it 'filters photos with an unknown taken date' do
      create(:photo, taken_at: Time.zone.now, taken_at_source: 'exif')
      unknown = create(:photo, taken_at: nil, taken_at_source: 'unknown')

      expect(search(unknown_date: true)).to contain_exactly(unknown)
    end

    it 'filters approximate-date photos' do
      create(:photo, taken_at_approximate: false)
      approximate = create(:photo, taken_at_approximate: true)

      expect(search(approximate_date: true)).to contain_exactly(approximate)
    end

    it 'filters to scanned photos' do
      scanned = create(:photo, :scanned)
      create(:photo)

      expect(search(scanned: true)).to contain_exactly(scanned)
    end
  end

  describe 'privacy' do
    it 'filters by privacy level' do
      create(:photo, privacy: 'public')
      private_photo = create(:photo, privacy: 'private')

      expect(search(privacy: 'private')).to contain_exactly(private_photo)
    end
  end

  describe 'sort' do
    it 'sorts by taken_at while keeping pg_search working (reorder across the rank join)' do
      older = create(:photo, title: 'lake photo', taken_at: Time.zone.local(2019, 1, 1))
      newer = create(:photo, title: 'lake photo', taken_at: Time.zone.local(2021, 1, 1))

      result = search(query: 'lake', sort: 'taken_at', direction: 'desc')
      expect(result.to_a).to eq([newer, older])
    end

    it 'sorts by impressions_count (local + Flickr)' do
      low = create(:photo, impressions_count: 1, flickr_impressions_count: 0)
      high = create(:photo, impressions_count: 5, flickr_impressions_count: 10)

      result = search(sort: 'impressions_count', direction: 'desc')
      expect(result.to_a).to eq([high, low])
    end
  end
end
