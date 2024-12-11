# frozen_string_literal: true

module Queries
  # Page Query
  class PageQuery < BaseQuery
    description 'Find a page by ID'

    type Types::PageType, null: false

    argument :id, ID, 'ID of the page', required: true

    def resolve(id:)
      title, markdown = PageService.fetch_page(id)

      { title: title, content: MarkdownToHtml.new(markdown).to_html }
    end
  end
end
