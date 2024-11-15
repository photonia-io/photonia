# frozen_string_literal: true

class SettingPolicy < ApplicationPolicy
  # These are in fact the Admin Settings

  def edit?
    user.present? && user.admin?
  end

  def update?
    edit?
  end
end
