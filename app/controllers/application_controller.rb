# frozen_string_literal: true

# This is the application controller, duh
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_settings
  before_action :set_gql_queries

  private

  def set_settings
    @settings = {
      root_path:,
      photos_path:,
      albums_path:,
      tags_path:,
      users_sign_in_path:,
      users_sign_out_path:,
      users_settings_path:,
      admin_path: admin_root_path,
      admin_users_path:,
      stats_path:,
      about_path:,
      privacy_policy_path:,
      terms_of_service_path:,
      graphql_path:,
      sentry_dsn: ENV.fetch('FE_SENTRY_DSN', ''),
      sentry_sample_rate: ENV.fetch('FE_SENTRY_SAMPLE_RATE', 0.1).to_f,
      site_name: Setting.site_name,
      site_description: Setting.site_description,
      site_tracking_code: Setting.site_tracking_code,
      continue_with_google_enabled: Setting.continue_with_google_enabled,
      continue_with_facebook_enabled: Setting.continue_with_facebook_enabled,
      rekognition_enabled: Setting.rekognition_enabled,
      commenting_enabled: Setting.commenting_enabled,
      photo_commenting_enabled: Setting.photo_commenting_enabled,
      album_commenting_enabled: Setting.album_commenting_enabled,
      homepage: Setting.homepage_sections,
      google_client_id: Setting.google_client_id,
      facebook_app_id: Setting.facebook_app_id
    }.to_json
  end

  def set_gql_queries
    @gql_queries = GraphqlQueryCollection::COLLECTION.to_json
  end

  # Shared by AlbumsController#show and PhotosController#show: a record not
  # visible server-side is either a real 404, or a valid share link, which
  # ships the same empty shell but as a 200 that stays out of search results
  # (there's no server-rendered content here either way). content_for is a
  # view helper, so the shell template reads @robots and sets it itself.
  def render_show_shell(shared:)
    @robots = 'noindex, nofollow' if shared
    render :show_shell, status: shared ? :ok : :not_found
  end
end
