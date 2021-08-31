# frozen_string_literal: true

# job for adding intelligent derivatives
class AddIntelligentDerivativesJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.unscoped.find(photo_id)
    photo.add_intelligent_derivatives
  end
end
