# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def page_url
    request.original_url
  end
end
