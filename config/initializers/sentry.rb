# frozen_string_literal: true

if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV.fetch('PHOTONIA_BE_SENTRY_DSN')
    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 0.5
    
    # or
    # config.traces_sampler = lambda do |context|
    #   true
    # end
  end
end
