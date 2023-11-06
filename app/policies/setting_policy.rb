# frozen_string_literal: true

class SettingPolicy < ApplicationPolicy
  def show?
    user.present? && user.admin?
  end

  def update?
    show?
  end
end
