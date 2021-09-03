# frozen_string_literal: true

# Tableless
class Configuration
  attr_accessor :root_path, :photos_path, :albums_path, :tags_path, :graphql_url

  def initialize(root_path:, photos_path:, albums_path:, tags_path:, graphql_url:)
    @root_path   = root_path
    @photos_path = photos_path
    @albums_path = albums_path
    @tags_path   = tags_path
    @graphql_url = graphql_url
  end
end
