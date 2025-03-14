# frozen_string_literal: true

namespace :flickr do
  desc 'Imports a Flickr export'
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
      original_filename = %r{[^/]+$}.match(photo_hash['original'])[0]
      photo_file_matches = photo_files.select { |i| i[/#{id}/] }
      break if photo_file_matches.size > 1

      photo_file = photo_file_matches[0]

      if photo_file
        photo = Photo.create(
          title: photo_hash['name'],
          description: photo_hash['description'],
          taken_at: photo_hash['date_taken'],
          license: photo_hash['license'],
          exif: photo_hash['exif'], # TODO: Import - This should be set later by our own means
          serial_number: photo_hash['id'],
          flickr_impressions_count: photo_hash['count_views'],
          flickr_faves: photo_hash['count_faves'],
          posted_at: photo_hash['date_imported'],
          flickr_photopage: photo_hash['photopage'],
          flickr_original: photo_hash['original'],
          flickr_json: photo_hash
          # TODO: Import - timezone: ? - deal with this some way
        )

        photo.image_attacher(model_cache: false)
        photo.image = File.open(photo_file, binmode: true)
        photo.image_derivatives!
        photo.save
      else
        not_found << "#{id} #{original_filename}"
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
    tagging_source = TaggingSource.find_by(name: 'Flickr')

    Photo.unscoped.all.each do |photo|
      flickr_tag_list = photo.flickr_json['tags'].map { |t| t['tag'].downcase }.join(',')
      if flickr_tag_list == ''
        puts "Photo #{photo.id} / #{photo.slug} - Not tagged"
      else
        tagging_source.tag(photo, with: flickr_tag_list, on: :tags)
        puts "Photo #{photo.id} / #{photo.slug} - Tagged with: #{flickr_tag_list}"
      end
    end
  end

  desc 'Import albums from Flickr'
  task import_albums: :environment do
    file = File.read("#{Rails.root}/flickr/json/albums.json")
    flickr_albums_hash = JSON.parse(file)
    flickr_albums = flickr_albums_hash['albums']

    flickr_albums.each do |flickr_album|
      album = Album.find_or_create_by(serial_number: flickr_album['id']) do |a|
        a.title = flickr_album['title']
        a.description = flickr_album['description']
        a.flickr_impressions_count = flickr_album['view_count']
        a.created_at = DateTime.strptime(flickr_album['created'], '%s')
        a.updated_at = DateTime.strptime(flickr_album['last_updated'], '%s')
      end

      puts "Created album: #{album.title}..."

      cover_photo_serial_number = /([0-9]+)$/.match(flickr_album['cover_photo'])[0]

      puts 'Adding photos...'

      ordering = 100_000

      flickr_album['photos'].each do |photo_serial_number|
        photo = Photo.find_by(serial_number: photo_serial_number)
        putc '.'

        next unless photo

        AlbumsPhoto.where(album_id: album.id, photo_id: photo.id).first_or_create do |relation|
          relation.ordering = ordering
          relation.cover = true if photo.serial_number == cover_photo_serial_number
        end

        photo.touch

        ordering += 100_000
      end

      puts '.'
    end
  end

  desc 'Import comments from Flickr'
  task import_comments: :environment do
    owner_flickr_user_nsid = '17448318@N00'

    Dir.glob("#{Rails.root}/flickr/json/photo_*.json").each do |file_name|
      file = File.read(file_name)
      photo_hash = JSON.parse(file)

      photo = Photo.unscoped.find_by(serial_number: photo_hash['id'])

      if photo.nil?
        puts "Photo not found: #{photo_hash['id']}"
        next
      end

      puts "Processing photo: #{photo_hash['id']} which has #{photo_hash['comments'].size} comments..."

      photo_hash['comments'].each do |comment_hash|
        # if this is the user who uploaded the photo, associate the comment with the user
        owner_flickr_user_nsid == comment_hash['user'] ? user = photo.user : user = nil
        flickr_user = FlickrUser.find_or_create_by(nsid: comment_hash['user'])

        comment = Comment.find_or_create_by(
          serial_number: comment_hash['id'],
          commentable: photo
        ) do |c|
          c.user = user
          c.flickr_user = flickr_user
          c.body = comment_hash['comment']
          c.flickr_link = comment_hash['url']
          c.created_at = DateTime.parse(comment_hash['date'])
        end

        puts "Created comment: #{comment.serial_number}..."
      end
    end
  end

  desc 'Get Flickr user data from the Flickr API'
  task fetch_user_data: :environment do
    seconds_between_requests = 10
    i = 0
    FlickrUser.where(is_deleted: nil).each do |flickr_user|
      FlickrPeopleGetInfoJob.set(wait: (seconds_between_requests * i).seconds).perform_later(flickr_user.id)
      i += 1
    end
  end
end
