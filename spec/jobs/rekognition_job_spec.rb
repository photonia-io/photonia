# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RekognitionJob do
  subject { described_class.perform_now(photo.id) }

  let(:photo) { build_stubbed(:photo) }
  let(:rekognition_tagger_instance) { double }
  let(:photo_labeler_instance) { double }

  before do
    allow(Photo).to receive(:find).and_return(photo)
    allow(photo).to receive(:reload).and_return(photo)
    allow(photo).to receive(:update_columns)
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

  it 'marks the photo as labeled' do
    expect(photo).to receive(:update_columns).with(labeled_at: kind_of(ActiveSupport::TimeWithZone))
    subject
  end

  it 'calls AddDerivativesJob' do
    expect(AddDerivativesJob).to receive(:perform_later).with(photo.id)
    subject
  end

  describe 'when Rekognition tagging keeps failing until attempts are exhausted' do
    let(:photo) { create(:photo) }

    before do
      allow(rekognition_tagger_instance).to receive(:tag).and_raise(StandardError, 'boom')
      allow(Sentry).to receive(:capture_exception)
    end

    # retry_on tracks attempts per job instance (exception_executions); preset
    # it past the configured attempts so perform_now hits the exhausted
    # branch immediately instead of actually retrying.
    def job_with_exhausted_attempts
      job = described_class.new(photo.id)
      job.exception_executions['[StandardError]'] = 20
      job
    end

    it 'records a terminal processing failure on the photo' do
      # Not photo.reload: the outer before block stubs #reload to a no-op.
      expect { job_with_exhausted_attempts.perform_now }
        .to change { Photo.unscoped.find(photo.id).processing_failed_at }.from(nil)
    end

    it 'reports the error to Sentry' do
      expect(Sentry).to receive(:capture_exception).with(instance_of(StandardError))
      job_with_exhausted_attempts.perform_now
    end
  end
end
