# frozen_string_literal: true

# Tableless
class Configuration
  attr_accessor :root_path, :photos_path, :albums_path, :tags_path, :users_sign_in_path, :users_sign_out_path, :graphql_url

  def initialize(root_path:, photos_path:, albums_path:, tags_path:, graphql_url:, users_sign_in_path:, users_sign_out_path:)
    @root_path   = root_path
    @photos_path = photos_path
    @albums_path = albums_path
    @tags_path   = tags_path
    @graphql_url = graphql_url
    @users_sign_in_path = users_sign_in_path
    @users_sign_out_path = users_sign_out_path
  end
end
