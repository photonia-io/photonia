# == Schema Information
#
# Table name: settings
#
#  id         :bigint           not null, primary key
#  value      :text
#  var        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_settings_on_var  (var) UNIQUE
#
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # Define your fields
  # field :host, type: :string, default: "http://localhost:3000"
  # field :default_locale, default: "en", type: :string
  # field :confirmable_enable, default: "0", type: :boolean
  # field :admin_emails, default: "admin@rubyonrails.org", type: :array
  # field :omniauth_google_client_id, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_ID"] || ""), type: :string, readonly: true
  # field :omniauth_google_client_secret, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_SECRET"] || ""), type: :string, readonly: true

  field :site_name, default: "Photonia", type: :string
  field :site_description, default: "Photonia is a photo sharing site.", type: :string
  field :site_tracking_code, default: ENV['PHOTONIA_TRACKING_CODE'] || "", type: :string
  field :continue_with_google_enabled, default: "0", type: :boolean
  field :continue_with_facebook_enabled, default: "0", type: :boolean
  field :mailer_from_name, default: ENV['PHOTONIA_MAILER_FROM_NAME'] || "Photonia", type: :string
  field :mailer_from_address, default: ENV['PHOTONIA_MAILER_FROM_ADDRESS'] || "mailer@photonia.io", type: :string
  field :google_client_id, default: ENV['PHOTONIA_GOOGLE_CLIENT_ID'] || "", type: :string, readonly: true
  field :facebook_app_id, default: ENV['PHOTONIA_FACEBOOK_APP_ID'] || "", type: :string, readonly: true
end
