# frozen_string_literal: true

require 'active_support/concern'

module HtmlDescriptionable
  extend ActiveSupport::Concern

  included do
    before_save :set_description_html, if: -> { description_changed? }

    private

    def set_description_html
      self.description_html = MarkdownToHtml.new(description).to_html
    end
  end
end
