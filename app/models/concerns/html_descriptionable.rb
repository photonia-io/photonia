# frozen_string_literal: true

require 'active_support/concern'

module HtmlDescriptionable
  extend ActiveSupport::Concern

  included do
    before_save :set_description_html, if: -> { description_changed? }

    private

    def set_description_html
      html = Kramdown::Document.new(description || '').to_html.strip
      self.description_html = (html == '<p></p>' ? '' : ActionController::Base.helpers.sanitize(html))
    end
  end
end
