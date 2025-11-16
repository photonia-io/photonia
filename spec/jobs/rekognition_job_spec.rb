# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RekognitionJob do
  subject { described_class.perform_now(photo.id) }

  let(:photo) { build_stubbed(:photo) }
  let(:rekognition_tagger_instance) { double }
  let(:photo_labeler_instance) { double }

  before do
    allow(Photo).to receive(:find).and_return(photo)
    allow(photo).to receive(:reload)
    allow(RekognitionTagger).to receive(:new).and_return(rekognition_tagger_instance)
    allow(rekognition_tagger_instance).to receive(:tag)
    allow(PhotoLabeler).to receive(:new).and_return(photo_labeler_instance)
    allow(photo_labeler_instance).to receive(:add_labels_from_rekognition_response)
  end

  it 'calls tag on the RekognitionTagger instance' do
    expect(rekognition_tagger_instance).to receive(:tag).with(photo)
    subject
  end

  it 'calls add_labels_from_rekognition_response on the PhotoLabeler instance' do
    expect(photo_labeler_instance).to receive(:add_labels_from_rekognition_response)
    subject
  end

  it 'calls AddDerivativesJob' do
    expect(AddDerivativesJob).to receive(:perform_later).with(photo.id)
    subject
  end
end
