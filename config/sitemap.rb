# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://photos.rusiczki.net'

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  add photos_path, priority: 0.5, changefreq: 'daily'

  Photo.find_each do |photo|
    add photo_path(photo), priority: 1.0, changefreq: 'monthly', lastmod: photo.updated_at
  end

  ActsAsTaggableOn::Tag.find_each do |tag|
    add tag_path(tag), priority: 0.3, changefreq: 'monthly', lastmod: tag.updated_at
  end

  Album.find_each do |album|
    add album_path(album), priority: 0.5, changefreq: 'monthly', lastmod: album.updated_at
  end
end
