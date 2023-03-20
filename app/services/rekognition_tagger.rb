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
    response = @client.detect_labels(
      image: {
        s3_object: {
          bucket: ENV.fetch('PHOTONIA_S3_BUCKET', nil),
          name: photo.image_data['derivatives']['extralarge']['id']
        }
      },
      max_labels: 50
    )

    photo.update_attribute(:rekognition_response, response.to_h)

    rekognition_tag_list = response.labels.map { |l| l.name.downcase }.join(',')
    @tagging_source.tag(photo, with: rekognition_tag_list, on: :tags)

    rekognition_tag_list
  end
end
