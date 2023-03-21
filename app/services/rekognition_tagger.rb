# frozen_string_literal: true

# Service class to tag photos via Amazon Rekognition
class RekognitionTagger
  def initialize
    @client = Aws::Rekognition::Client.new(
      region: ENV.fetch('PHOTONIA_S3_REGION', nil),
      access_key_id: ENV.fetch('PHOTONIA_REKOGNITION_ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('PHOTONIA_REKOGNITION_SECRET_ACCESS_KEY', nil)
    )
    @tagging_source = TaggingSource.find_by(name: 'Rekognition')
  end

  def tag(photo)
    rekognition_labels = detect_labels(photo)
    rekognition_tag_list = rekognition_labels.join(',')
    @tagging_source.tag(photo, with: rekognition_tag_list, on: :tags)
    rekognition_tag_list
  end

  private

  def detect_labels(photo)
    response = @client.detect_labels(
      image: { s3_object: s3_object(photo) },
      max_labels: 50
    )
    photo.rekognition_response = response.to_h
    photo.save(validate: false)
    response.labels.map { |l| l.name.downcase }
  end

  def s3_object(photo)
    {
      bucket: ENV.fetch('PHOTONIA_S3_BUCKET', nil),
      name: photo.image.path
    }
  end
end
