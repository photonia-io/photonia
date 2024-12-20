# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class AdminMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/admin_mailer/new_social_user
  def new_social_user
    AdminMailer.with(
      provider: 'Google',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@domain.com',
      admin_emails: 'admin@photonia.io'
    ).new_social_user
  end

end
