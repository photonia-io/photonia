require 'rails_helper'

RSpec.describe AdminMailer, type: :mailer do
  let(:provider) { 'Test Provider' }
  let(:first_name) { 'Test First Name' }
  let(:last_name) { 'Test Last Name' }
  let(:email) { 'user.email@domain.com' }
  let(:admin_emails) { ['admin.email.1@domain.com', 'admin.email.2@domain.com'] }

  describe 'new_provider_user' do
    let(:mail) do
      AdminMailer.with(
        provider:,
        first_name:,
        last_name:,
        email:,
        admin_emails:
      ).new_provider_user
    end

    it 'renders the headers' do
      expect(mail.subject).to eq("New user signed up via #{provider}")
      expect(mail.to).to eq(admin_emails)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include("A new user signed up via <em>#{provider}</em>")
      expect(mail.body.encoded).to include(first_name)
      expect(mail.body.encoded).to include(last_name)
      expect(mail.body.encoded).to include(email)
    end
  end
end
