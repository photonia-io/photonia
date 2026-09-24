# frozen_string_literal: true

# job for adding intelligent derivatives
class AddDerivativesJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.unscoped.find(photo_id)
    photo.add_derivatives
    photo.update_columns(processed_at: Time.current)
  end
end
