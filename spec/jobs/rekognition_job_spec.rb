require 'rails_helper'

RSpec.describe RekognitionJob, type: :job do
  let(:photo) { build_stubbed(:photo) }
  let(:rekognition_tagger_instance) { double }

  before do
    allow(Photo).to receive(:find).and_return(photo)
    allow(RekognitionTagger).to receive(:new).and_return(rekognition_tagger_instance)
    allow(rekognition_tagger_instance).to receive(:tag)
  end

  subject { described_class.perform_now(photo.id) }

  it 'calls tag on the RekognitionTagger instance' do
    expect(rekognition_tagger_instance).to receive(:tag).with(photo)
    subject
  end

  it 'calls AddIntelligentDerivativesJob' do
    expect(AddIntelligentDerivativesJob).to receive(:perform_later).with(photo.id)
    subject
  end
end
