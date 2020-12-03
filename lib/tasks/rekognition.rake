# frozen_string_literal: true

namespace :rekognition do
  desc 'Recognizes stuff in photos'
  task tag_batch: :environment do
    batch_size = 500

    batch = Photo.unscoped.all.where(rekognition_response: nil).limit(batch_size)

    client = Aws::Rekognition::Client.new(
      region: ENV['PHOTONIA_S3_REGION'],
      access_key_id: ENV['PHOTONIA_REKOGNITION_ACCESS_KEY_ID'],
      secret_access_key: ENV['PHOTONIA_REKOGNITION_SECRET_ACCESS_KEY']
    )

    tagging_source = TaggingSource.find_by(name: 'Rekognition')

    batch.each do |photo|
      response = client.detect_labels(
        image: {
          s3_object: {
            bucket: ENV['PHOTONIA_S3_BUCKET'],
            name: photo.image_data['derivatives']['extralarge']['id']
          }
        },
        max_labels: 50
      )

      photo.update_attribute(:rekognition_response, response.to_h)

      rekognition_tag_list = response.labels.map { |l| l.name.downcase }.join(',')
      tagging_source.tag(photo, with: rekognition_tag_list, on: :tags)

      puts "Photo #{photo.id} / #{photo.slug} - Tagged with: #{rekognition_tag_list}"
    end
  end

  task tag_from_responses: :environment do
    tagging_source = TaggingSource.find_by(name: 'Rekognition')

    Photo.unscoped.all.where.not(rekognition_response: nil).each do |photo|
      rekognition_tag_list = photo.rekognition_response['labels'].map { |l| l['name'].downcase }.join(',')
      tagging_source.tag(photo, with: rekognition_tag_list, on: :tags)

      puts "Photo #{photo.id} / #{photo.slug} - Tagged with: #{rekognition_tag_list}"
    end
  end
end
