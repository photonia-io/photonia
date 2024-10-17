# frozen_string_literal: true

class MarkdownToHtml
  def initialize(markdown)
    @markdown = markdown
  end

  def to_html
    html = Kramdown::Document.new(@markdown || '').to_html.strip
    (html == '<p></p>' ? '' : ActionController::Base.helpers.sanitize(html))
  end
end
