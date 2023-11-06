# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0', 'xmlns:media': 'http://search.yahoo.com/mrss/' do
  xml.channel do
    xml.title Setting.site_name + ' - Photos'
    xml.description 'Photos by Janos Rusiczki'
    xml.link photos_url

    @photos.each do |photo|
      next unless (medium_image = photo.image(:medium))

      thumbnail_image = photo.image(:thumbnail_intelligent).presence || photo.image(:thumbnail_square)
      xml.item do
        xml.title photo.name
        xml.description photo.description
        xml.pubDate photo.created_at.to_fs(:rfc822)
        xml.link photo_url(photo)
        xml.guid photo_url(photo)
        xml.media :content, url: medium_image.url, type: medium_image.mime_type, width: medium_image.width,
                            height: medium_image.height
        xml.media title: photo.name
        xml.media description: photo.description
        xml.media :thumbnail, url: thumbnail_image.url, width: thumbnail_image.width, height: thumbnail_image.height
        xml.media :credit, role: 'photographer', content: 'Janos Rusiczki'
      end
    end
  end
end
