# frozen_string_literal: true

# Tableless
class Configuration
  attr_accessor :root_path, :photos_path, :albums_path, :tags_path

  def initialize(root_path:, photos_path:, albums_path:, tags_path:)
    @root_path = root_path
    @photos_path = photos_path
    @albums_path = albums_path
    @tags_path = tags_path
  end
end
