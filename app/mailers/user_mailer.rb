class UserMailer < ApplicationMailer
  def flickr_claim_approved
    @user = params[:user]
    @flickr_user = params[:flickr_user]
    mail to: @user.email, subject: 'Your Flickr user claim has been approved'
  end

  def flickr_claim_denied
    @user = params[:user]
    @flickr_user = params[:flickr_user]
    mail to: @user.email, subject: 'Your Flickr user claim has been denied'
  end
end
