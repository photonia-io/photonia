require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:flickr_user) { create(:flickr_user) }

  describe 'flickr_claim_approved' do
    let(:claim) { create(:flickr_user_claim, :automatic, :approved, user: user, flickr_user: flickr_user) }
    let(:mail) do
      UserMailer.with(
        user: user,
        flickr_user: flickr_user,
        claim: claim
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

    it 'tells the user to remove the verification code for an automatic claim' do
      expect(mail.html_part.body.encoded).to include('remove the verification code')
      expect(mail.text_part.body.encoded).to include('remove the verification code')
    end

    context 'when the claim was manual' do
      let(:claim) { create(:flickr_user_claim, :manual, :approved, user: user, flickr_user: flickr_user) }

      it 'does not mention a verification code' do
        expect(mail.html_part.body.encoded).not_to include('verification code')
        expect(mail.text_part.body.encoded).not_to include('verification code')
      end
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
