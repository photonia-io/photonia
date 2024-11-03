# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Setting.mailer_from
  layout 'mailer'
end
