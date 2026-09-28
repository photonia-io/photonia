# frozen_string_literal: true

# View helpers shared across ERB pages, including the SEO head tags
# (canonical, robots, description, structured data) rendered in the layout.
module ApplicationHelper
  include Pagy::Frontend

  DESCRIPTION_MAX_LENGTH = 160

  # Query params that produce genuinely different content and so stay on
  # the canonical URL (self-referencing); anything else - ?inAlbum=, view
  # state, tracking params - is view state, not content, and gets dropped.
  # See #1088.
  CANONICAL_ALLOWED_PARAMS = %w[page q].freeze

  def page_url
    request.original_url
  end

  # Canonical URL for the current page. `path` defaults to the current
  # request path, but a view resolves it explicitly via content_for(:canonical_url)
  # when it needs the record's own friendly_id slug (which can differ from
  # the requested path, e.g. an old/aliased slug) - never a database id.
  def canonical_url(path = request.path)
    explicit = content_for(:canonical_url)
    return explicit if explicit.present?

    query = request.query_parameters.slice(*CANONICAL_ALLOWED_PARAMS)
    url = request.base_url + path
    url += "?#{query.to_query}" if query.present?
    url
  end

  def meta_description
    explicit = content_for(:meta_description)
    explicit.presence || truncate_description(Setting.site_description)
  end

  # Falls back to a description built from title/date/tags when the photo
  # has none of its own, so a page never ships an empty meta description.
  def photo_meta_description(photo, tags: [], rekognition_tags: [])
    return truncate_description(strip_tags(photo.description_html)) if photo.description_html.presence

    parts = ["#{photo.title.presence || 'Untitled photo'}."]
    parts << "Photo taken #{photo.taken_at_text}." if photo.taken_at_text.present?

    tag_names = (tags + rekognition_tags).first(6).map(&:name)
    parts << "Tagged #{tag_names.to_sentence}." if tag_names.any?

    truncate_description(parts.join(' '))
  end

  # ImageObject JSON-LD for a photo page - helps Google Images pick up
  # title, license and date without re-deriving them from the page text.
  def photo_structured_data(photo)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'ImageObject',
      'contentUrl' => photo.image_url(:extralarge),
      'thumbnailUrl' => photo.image_url(:medium_intelligent).presence || photo.image_url(:medium_square),
      'name' => photo.title,
      'description' => strip_tags(photo.description_html).presence,
      'datePublished' => photo.posted_at&.iso8601,
      'dateCreated' => photo.taken_at&.iso8601,
      'creator' => {
        '@type' => 'Person',
        'name' => photo.user.display_name
      },
      'creditText' => photo.user.display_name,
      'copyrightNotice' => photo.license
    }.compact

    license_url = License.url_for(photo.license)
    data['license'] = license_url if license_url

    content_tag(:script, json_escape(data.to_json).html_safe, type: 'application/ld+json')
  end

  private

  def truncate_description(text)
    text.to_s.squish.truncate(DESCRIPTION_MAX_LENGTH, separator: ' ')
  end
end
