# frozen_string_literal: true

namespace :rekognition do
  desc 'Recognizes stuff in photos'
  task tag_batch: :environment do
    batch_size = 500

    batch = Photo.unscoped.all.where(rekognition_response: nil).limit(batch_size)

    rekognition_tagger = RekognitionTagger.new

    batch.each do |photo|
      rekognition_tag_list = rekognition_tagger.tag(photo)
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
