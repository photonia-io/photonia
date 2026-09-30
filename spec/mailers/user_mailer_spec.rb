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

    it 'tells the user they can now edit or delete their imported comments' do
      expect(mail.html_part.body.encoded).to include('edit or delete')
      expect(mail.text_part.body.encoded).to include('edit or delete')
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

  describe 'new_comment' do
    let(:owner) { create(:user) }
    let(:commenter) { create(:user, display_name: 'Jane Doe') }
    let(:mail) { UserMailer.with(comment: comment).new_comment }

    context 'when the commentable is a photo' do
      let(:photo) { create(:photo, user: owner, title: 'Sunset') }
      let(:comment) { create(:comment, commentable: photo, user: commenter, body: 'Lovely shot') }

      it 'renders the headers' do
        expect(mail.subject).to eq('New comment on your photo: Sunset')
        expect(mail.to).to eq([owner.email])
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include('Jane Doe')
        expect(mail.body.encoded).to include('Lovely shot')
        expect(mail.body.encoded).to include(photo_url(photo))
      end
    end

    context 'when the commentable is an album' do
      let(:album) { create(:album, user: owner, title: 'Vacation') }
      let(:comment) { create(:comment, commentable: album, user: commenter, body: 'Great album') }

      it 'renders the headers' do
        expect(mail.subject).to eq('New comment on your album: Vacation')
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include('Great album')
        expect(mail.body.encoded).to include(album_url(album))
      end
    end

    context 'when the commentable has no title' do
      let(:photo) { create(:photo, user: owner, title: nil, description: 'A photo') }
      let(:comment) { create(:comment, commentable: photo, user: commenter) }

      it 'falls back to "untitled"' do
        expect(mail.subject).to eq('New comment on your photo: untitled')
      end
    end

    context 'when the commentable is private' do
      let(:photo) { create(:photo, user: owner, privacy: :private, title: 'Hidden') }
      let(:comment) { create(:comment, commentable: photo, user: commenter) }

      it 'still resolves the commentable and its owner' do
        expect(mail.to).to eq([owner.email])
      end
    end
  end

  describe 'comment_reply' do
    let(:parent_author) { create(:user) }
    let(:replier) { create(:user, display_name: 'Jane Doe') }
    let(:photo) { create(:photo, user: create(:user), title: 'Sunset') }
    let(:parent) { create(:comment, commentable: photo, user: parent_author, body: 'Original comment') }
    let(:comment) { create(:comment, commentable: photo, user: replier, parent: parent, body: 'A reply') }
    let(:mail) { UserMailer.with(comment: comment).comment_reply }

    it 'renders the headers' do
      expect(mail.subject).to eq('New reply to your comment on Sunset')
      expect(mail.to).to eq([parent_author.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Jane Doe')
      expect(mail.body.encoded).to include('A reply')
      expect(mail.body.encoded).to include(photo_url(photo))
    end
  end
end
