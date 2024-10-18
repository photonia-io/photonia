# frozen_string_literal: true

class PageService
  def self.fetch_page(id)
    case id
    when 'about'
      title = 'About'
      page = 'about.markdown'
    when 'privacy-policy'
      title = 'Privacy Policy'
      page = 'privacy_policy.markdown'
    when 'terms-of-service'
      title = 'Terms of Service'
      page = 'terms_of_service.markdown'
    else
      raise "Invalid page ID"
    end

    [
      title,
      File.read(Rails.root.join('app', 'views', 'pages', page))
    ]
  end
end
