# frozen_string_literal: true

# job for doing background Rekognition tagging
class RekognitionJob < ApplicationJob
  queue_as :default

  # Once ActiveJob gives up retrying, record it as a terminal failure instead
  # of leaving the photo to poll as "processing" forever - AddDerivativesJob
  # (and therefore processed_at) never runs without this job succeeding first.
  retry_on StandardError, wait: :polynomially_longer, attempts: 10 do |job, error|
    Sentry.capture_exception(error)
    Photo.unscoped.where(id: job.arguments.first).update_all(processing_failed_at: Time.current)
  end

  def perform(photo_id)
    photo = Photo.find(photo_id)
    RekognitionTagger.new.tag(photo)
    PhotoLabeler.new(photo.reload).add_labels_from_rekognition_response
    photo.update_columns(labeled_at: Time.current)
    AddDerivativesJob.perform_later(photo_id)
  end
end
