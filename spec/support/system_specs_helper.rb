module SystemSpecsHelper
  def sign_in_with(email:, password:)
    visit(users_sign_in_path)
    fill_in('email', with: email)
    fill_in('password', with: password)
    click_button('Sign In')
  end
end
