require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }

  describe 'flickr_claim_approved' do
    let(:mail) do
      UserMailer.with(
        user: user,
        flickr_user: flickr_user
      ).flickr_claim_approved
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Your Flickr user claim has been approved')
      expect(mail.to).to eq([user.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(flickr_user.username)
      expect(mail.body.encoded).to include('approved')
    end
  end

  describe 'flickr_claim_denied' do
    let(:mail) do
      UserMailer.with(
        user: user,
        flickr_user: flickr_user
      ).flickr_claim_denied
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Your Flickr user claim has been denied')
      expect(mail.to).to eq([user.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(flickr_user.username)
      expect(mail.body.encoded).to include('denied')
    end
  end
end
