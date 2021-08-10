# frozen_string_literal: true

# job for doing background Rekognition tagging
class RekognitionJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find(photo_id)
    rekognition_tagger = RekognitionTagger.new
    rekognition_tagger.tag(photo)
    AddIntelligentDerivativesJob.perform_later(photo_id)
  end
end
