# frozen_string_literal: true

# Controller for static pages
class PagesController < ApplicationController
  def handler
    # get the last part of the URL
    id = request.path.split('/').last
    @title, markdown = PageService.fetch_page(id)
    @content = MarkdownToHtml.new(markdown).to_html
  end
end
