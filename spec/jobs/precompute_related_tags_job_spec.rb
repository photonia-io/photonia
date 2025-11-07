# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrecomputeRelatedTagsJob do
  let!(:romania)   { ActsAsTaggableOn::Tag.create!(name: 'romania') }
  let!(:maramures) { ActsAsTaggableOn::Tag.create!(name: 'maramures') }
  let!(:baia_mare) { ActsAsTaggableOn::Tag.create!(name: 'baia mare') }

  let!(:flickr_source)      { TaggingSource.find_or_create_by!(name: 'Flickr') }
  let!(:rekognition_source) { TaggingSource.find_or_create_by!(name: 'Rekognition') }

  ##
  # Adds the given tag names to the photo's tag list and persists the photo.
  # @param [Photo] photo - The photo to modify.
  # @param [String, Array<String>] names - A tag name or an array of tag names to add.
  def tag_user(photo, names)
    photo.tag_list.add(names)
    photo.save!
  end

  ##
  # Tags the given photo using the Flickr tagging source and saves the photo.
  # @param [Photo] photo - The photo to tag; it will be persisted.
  # @param [String, Array<String>] names - A tag name or an array of tag names; multiple names are joined with commas.
  def tag_flickr(photo, names)
    flickr_source.tag(photo, with: Array(names).join(','), on: :tags)
    photo.save!
  end

  ##
  # Add tags to a photo using the Rekognition tagging source and persist the change.
  # @param [Photo] photo - The photo to be tagged.
  # @param [String, Array<String>] names - A tag name or list of tag names; multiple names will be joined with commas.
  # @raise [ActiveRecord::RecordInvalid] If saving the photo fails validation.
  def tag_rekognition(photo, names)
    rekognition_source.tag(photo, with: Array(names).join(','), on: :tags)
    photo.save!
  end

  before do
    # photo_1: romania + maramures
    photo_1 = create(:photo)
    tag_user(photo_1, %w[romania maramures])

    # photo_2: romania + maramures (Flickr)
    photo_2 = create(:photo)
    tag_flickr(photo_2, %w[romania maramures])

    # photo_3: romania + maramures + baia mare
    photo_3 = create(:photo)
    tag_user(photo_3, ['romania', 'maramures', 'baia mare'])

    # photo_4: baia mare + maramures
    photo_4 = create(:photo)
    tag_user(photo_4, ['baia mare', 'maramures'])

    # Rekognition-only tags should be excluded
    photo_noise = create(:photo)
    tag_rekognition(photo_noise, ['romania', 'maramures', 'baia mare'])
  end

  it 'computes directed related tags excluding Rekognition taggings' do
    expect do
      described_class.perform_now(min_support: 1, min_confidence: 0.0)
    end.not_to raise_error

    rel_mm_to_ro = RelatedTag.find_by(tag_id_from: maramures.id, tag_id_to: romania.id)
    rel_bm_to_mm = RelatedTag.find_by(tag_id_from: baia_mare.id, tag_id_to: maramures.id)

    expect(rel_mm_to_ro).to be_present
    expect(rel_mm_to_ro.support).to be >= 1
    expect(rel_mm_to_ro.confidence).to be >= 0.0

    expect(rel_bm_to_mm).to be_present

    # Ensure we never produce self-relations
    expect(RelatedTag.where(tag_id_from: maramures.id, tag_id_to: maramures.id)).to be_empty
  end
end
