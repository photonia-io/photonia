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
      users_admin_settings_path:,
      admin_path:,
      admin_settings_path:,
      admin_users_path:,
      stats_path:,
      about_path:,
      privacy_policy_path:,
      terms_of_service_path:,
      graphql_path:,
      sentry_dsn: ENV.fetch('PHOTONIA_FE_SENTRY_DSN', ''),
      sentry_sample_rate: ENV.fetch('PHOTONIA_FE_SENTRY_SAMPLE_RATE', 0.1).to_f,
      site_name: Setting.site_name,
      site_description: Setting.site_description,
      site_tracking_code: Setting.site_tracking_code,
      continue_with_google_enabled: Setting.continue_with_google_enabled,
      continue_with_facebook_enabled: Setting.continue_with_facebook_enabled,
      google_client_id: Setting.google_client_id,
      facebook_app_id: Setting.facebook_app_id
    }.to_json
  end

  def set_gql_queries
    @gql_queries = GraphqlQueryCollection::COLLECTION.to_json
  end
end
