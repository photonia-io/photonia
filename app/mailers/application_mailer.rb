# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "#{Setting.mailer_from_name} <#{Setting.mailer_from_address}>"
  layout 'mailer'
end
