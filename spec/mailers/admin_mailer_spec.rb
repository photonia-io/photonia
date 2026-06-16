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

  describe 'flickr_claim_request' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:claim) { create(:flickr_user_claim, user: user, flickr_user: flickr_user, claim_type: 'manual') }
    let(:reason) { 'Lost access to my Flickr account' }
    let(:mail) do
      AdminMailer.with(
        user: user,
        flickr_user: flickr_user,
        claim: claim,
        reason: reason,
        admin_emails: admin_emails
      ).flickr_claim_request
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('New Flickr user claim request')
      expect(mail.to).to eq(admin_emails)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(user.email)
      expect(mail.body.encoded).to include(flickr_user.username)
      expect(mail.body.encoded).to include(flickr_user.nsid)
      expect(mail.body.encoded).to include(reason)
    end

    it 'includes user admin link' do
      expect(mail.body.encoded).to include("/admin/users/#{user.slug}")
    end
  end

  describe 'flickr_claim_approved' do
    let(:user) { create(:user) }
    let(:flickr_user) { create(:flickr_user) }
    let(:claim) do
      create(:flickr_user_claim,
             user: user,
             flickr_user: flickr_user,
             claim_type: 'automatic',
             status: 'approved',
             verified_at: Time.current)
    end
    let(:mail) do
      AdminMailer.with(
        user: user,
        flickr_user: flickr_user,
        claim: claim,
        admin_emails: admin_emails
      ).flickr_claim_approved
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Flickr user claim approved')
      expect(mail.to).to eq(admin_emails)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(user.email)
      expect(mail.body.encoded).to include(flickr_user.username)
      expect(mail.body.encoded).to include(flickr_user.nsid)
      expect(mail.body.encoded).to include('Automatic')
      expect(mail.body.encoded).to include('Approved')
    end

    it 'includes user admin link' do
      expect(mail.body.encoded).to include("/admin/users/#{user.slug}")
    end
  end
end
