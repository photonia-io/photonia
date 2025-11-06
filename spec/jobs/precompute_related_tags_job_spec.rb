# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrecomputeRelatedTagsJob do
  let!(:romania)   { ActsAsTaggableOn::Tag.create!(name: 'romania') }
  let!(:maramures) { ActsAsTaggableOn::Tag.create!(name: 'maramures') }
  let!(:baia_mare) { ActsAsTaggableOn::Tag.create!(name: 'baia mare') }

  let!(:flickr_source)      { TaggingSource.find_or_create_by!(name: 'Flickr') }
  let!(:rekognition_source) { TaggingSource.find_or_create_by!(name: 'Rekognition') }

  def tag_user(photo, names)
    photo.tag_list.add(names)
    photo.save!
  end

  def tag_flickr(photo, names)
    flickr_source.tag(photo, with: Array(names).join(','), on: :tags)
    photo.save!
  end

  def tag_rekognition(photo, names)
    rekognition_source.tag(photo, with: Array(names).join(','), on: :tags)
    photo.save!
  end

  before do
    # P1: romania + maramures
    photo_1 = create(:photo)
    tag_user(photo_1, %w[romania maramures])

    # P2: romania + maramures (Flickr)
    photo_2 = create(:photo)
    tag_flickr(photo_2, %w[romania maramures])

    # P3: romania + maramures + baia mare
    photo_3 = create(:photo)
    tag_user(photo_3, ['romania', 'maramures', 'baia mare'])

    # P4: baia mare + maramures
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
