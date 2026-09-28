# frozen_string_literal: true

class PromoteJob < ApplicationJob
  def perform(attacher_class, record_class, record_id, name, file_data)
    attacher_class = Object.const_get(attacher_class)
    record         = Object.const_get(record_class).find(record_id)

    attacher = attacher_class.retrieve(
      model: record,
      name:,
      file: file_data
    )

    attacher.create_derivatives
    attacher.atomic_promote

    if attacher.stored? && record_class == 'Photo'
      if Setting.rekognition_enabled
        RekognitionJob.perform_later(record_id)
      else
        AddDerivativesJob.perform_later(record_id)
      end
    end
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
