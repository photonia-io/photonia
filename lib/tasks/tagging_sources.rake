namespace :tagging_sources do
  desc 'Add Tagging Source'
  task create: :environment do
    TaggingSource.find_or_create_by(name: 'Flickr')
    TaggingSource.find_or_create_by(name: 'Rekognition')
  end
end
