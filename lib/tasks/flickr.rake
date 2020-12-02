# frozen_string_literal: true

namespace :flickr do
  desc "Imports a Flickr export (from 2018)"
  task import: :environment do
    photo_files = []
    Dir.glob("#{Rails.root}/flickr/photos/*.{jpg,png}").each do |file_name|
      photo_files << file_name
    end

    not_found = []

    Dir.glob("#{Rails.root}/flickr/json/photo_*.json").each do |file_name|
      file = File.read(file_name)
      photo_hash = JSON.parse(file)

      id = photo_hash['id']
      original_filename = %r{[^\/]+$}.match(photo_hash['original'])[0]
      photo_file_matches = photo_files.select { |i| i[/#{id}/] }
      break if photo_file_matches.size > 1

      photo_file = photo_file_matches[0]

      if photo_file
        photo = Photo.create(
          name: photo_hash['name'],
          description: photo_hash['description'],
          date_taken: photo_hash['date_taken'],
          license: photo_hash['license'],
          exif: photo_hash['exif'],
          flickr_id: photo_hash['id'],
          flickr_views: photo_hash['count_views'],
          flickr_faves: photo_hash['count_faves'],
          flickr_date_imported: photo_hash['date_imported'],
          flickr_photopage: photo_hash['photopage'],
          flickr_original: photo_hash['original'],
          flickr_json: photo_hash
        )

        photo.image_attacher(model_cache: false)
        photo.image = File.open(photo_file, binmode: true)
        photo.image_derivatives!
        photo.save
      else
        not_found << id + ' ' + original_filename
      end

      putc '.'
    end

    puts ''
    puts not_found
  end

  desc 'Sets the privacy of Flickr photos according to the original JSON'
  task import_privacy: :environment do
    affected_rows = ActiveRecord::Base.connection.update("UPDATE photos SET privacy = (flickr_json->>'privacy')::photo_privacy")
    puts "#{affected_rows} photos updated"
  end

  desc 'Import tags from Flickr'
  task import_tags: :environment do
    Photo.unscoped.all.each do |photo|
      tags = photo.flickr_json['tags'].each.pluck('tag')
      photo.tag_list = tags
      photo.save
      putc '.'
    end
    ActsAsTaggableOn::Tag.update_all(source: 'flickr')
    puts ''
  end

  desc 'Fix tagging'
  task fix_tagging: :environment do
    tagging_source = TaggingSource.find_by(name: 'Flickr')
    ActsAsTaggableOn::Tagging.update_all(
      tagger_type: tagging_source.class.name,
      tagger_id: tagging_source.id
    )
  end
end
