class AdminMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.admin_mailer.new_provider_user.subject
  #
  def new_provider_user
    @provider = params[:provider]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @email = params[:email]
    mail to: params[:admin_emails], subject: "New user signed up via #{@provider}"
  end

  def flickr_claim_request
    @user = params[:user]
    @flickr_user = params[:flickr_user]
    @claim = params[:claim]
    @reason = params[:reason]
    @user_admin_url = admin_show_user_url(@user.slug)
    mail to: params[:admin_emails], subject: 'New Flickr user claim request'
  end
end
