# frozen_string_literal: true

class PagesController < ApplicationController
  def handler
    # get the last part of the URL
    id = request.path.split('/').last
    @title, markdown = PageService.fetch_page(id)
    @content = Kramdown::Document.new(markdown).to_html.html_safe
  end
end
