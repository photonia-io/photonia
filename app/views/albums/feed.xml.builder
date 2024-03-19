# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title Setting.site_name + ' - Albums'
    xml.description 'Albums by Janos Rusiczki'
    xml.link albums_url

    @albums.each do |album|
      xml.item do
        xml.title album.title
        xml.description album.description
        xml.pubDate album.created_at.to_fs(:rfc822)
        xml.link album_url(album)
        xml.guid album_url(album)
        if (cover_image = album.public_cover_photo&.image(:medium_intelligent).presence || album.public_cover_photo&.image(:medium_square))
          xml.enclosure url: cover_image.url, type: cover_image.mime_type, length: cover_image.size
        end
      end
    end
  end
end
