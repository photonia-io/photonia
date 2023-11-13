# frozen_string_literal: true

require 'rails_helper'

describe 'Sign In' do
  let(:email) { 'user@domain.com' }
  let(:password) { 'Password123!' }

  before do
    create(:user, email:, password:)
  end

  context 'with valid email and password' do
    it 'signs in the user and redirects to user settings page' do
      sign_in_with(email:, password:)
      expect(page).to have_current_path(users_settings_path)
      expect(page).to have_field('email', with: email, disabled: true)
    end
  end

  context 'with invalid email' do
    it 'displays an error message' do
      sign_in_with(email: 'another.user@domain.com', password:)
      expect(page).to have_content('There was an error signing you in. Please try again.')
    end
  end

  context 'with invalid password' do
    it 'displays an error message' do
      sign_in_with(email:, password: 'wrongpassword')
      expect(page).to have_content('There was an error signing you in. Please try again.')
    end
  end
end
