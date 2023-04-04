# frozen_string_literal: true

# Service class to add labels to photos
class PhotoLabeler
  def initialize(photo)
    @photo = photo
  end

  def add_labels_from_rekognition_response
    rekognition_labels.each do |rekognition_label_name, rekognition_label_instances|
      rekognition_label_instances.each do |rekognition_label_instance|
        Label.find_or_create_from_rekognition_label_instance(
          @photo,
          rekognition_label_name,
          rekognition_label_instance
        )
      end
    end
    @photo.labels
  end

  private

  def rekognition_labels
    labels = Hash.new(0)
    @photo.rekognition_response['labels'].each do |label|
      next unless (instances = label['instances'].presence)

      labels[label['name']] = instances
    end
    labels
  end
end
