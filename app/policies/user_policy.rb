# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user.present? && user.admin?
  end

  def show?
    user.present? && user.admin?
  end

  def edit?
    user.present? && (user.admin? || record.id == user.id)
  end

  def update?
    edit?
  end
end
