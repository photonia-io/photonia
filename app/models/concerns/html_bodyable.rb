# frozen_string_literal: true

require 'active_support/concern'

module HtmlBodyable
  extend ActiveSupport::Concern

  included do
    before_save :set_body_html, if: -> { body_changed? }

    private

    def set_body_html
      self.body_html = MarkdownToHtml.new(body).to_html
    end
  end
end
