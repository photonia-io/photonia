# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def edit?
    user.present? && (user.admin? || record.id == user.id)
  end

  def update?
    edit?
  end
end
