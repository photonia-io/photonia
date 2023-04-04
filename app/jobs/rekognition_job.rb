# frozen_string_literal: true

# job for doing background Rekognition tagging
class RekognitionJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find(photo_id)
    RekognitionTagger.new.tag(photo)
    PhotoLabeler.new(photo.reload).add_labels_from_rekognition_response
    AddIntelligentDerivativesJob.perform_later(photo_id)
  end
end
