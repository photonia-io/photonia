# frozen_string_literal: true

class ImpressionPolicy < ApplicationPolicy
  def index?
    user.present?
  end
end
