require 'rails_helper'

describe 'Sign In' do
  let(:email) { 'user@domain.com' }
  let(:password) { 'Password123!' }

  before do
    create(:user, email: email, password: password)
  end

  context 'with valid email and password' do
    it 'signs in the user' do
      sign_in_with(email, password)
      expect(page).to have_field('email', with: email, disabled: true)
    end
  end

  context 'with invalid email' do
    it 'does not sign in the user' do
      sign_in_with('another.user@domain.com', password)
      expect(page).to have_content('There was an error signing you in. Please try again.')
    end
  end

  context 'with invalid password' do
    it 'does not sign in the user' do
      sign_in_with(email, 'wrongpassword')
      expect(page).to have_content('There was an error signing you in. Please try again.')
    end
  end
end


