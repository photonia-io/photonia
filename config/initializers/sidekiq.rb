# frozen_string_literal: true

if Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq::Testing.fake!
  Sidekiq.configure_client do |config|
    config.logger.level = Logger::WARN
  end
else
  sidekiq_config = { url: ENV.fetch('PHOTONIA_REDIS_URL', nil) }

  Sidekiq.configure_server do |config|
    config.redis = sidekiq_config
  end

  Sidekiq.configure_client do |config|
    config.redis = sidekiq_config
  end
end
