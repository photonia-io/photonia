# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class AdminMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/admin_mailer/new_provider_user
  def new_provider_user
    AdminMailer.with(
      provider: 'Google',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@domain.com',
      admin_emails: 'admin@photonia.io'
    ).new_provider_user
  end
end
