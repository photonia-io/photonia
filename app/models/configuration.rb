# frozen_string_literal: true

# Tableless
class Configuration
  attr_accessor :root_path, :graphql_url, :photos_path, :albums_path, :tags_path, :users_sign_in_path, :users_sign_out_path, :users_settings_path

  def initialize(root_path:, graphql_url:, photos_path:, albums_path:, tags_path:, users_sign_in_path:, users_sign_out_path:, users_settings_path:)
    @root_path   = root_path
    @graphql_url = graphql_url
    @photos_path = photos_path
    @albums_path = albums_path
    @tags_path   = tags_path
    @users_sign_in_path = users_sign_in_path
    @users_sign_out_path = users_sign_out_path
    @users_settings_path = users_settings_path
  end
end
