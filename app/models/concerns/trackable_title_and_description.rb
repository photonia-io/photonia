# frozen_string_literal: true

# Title/description edit helpers; the including model must track both
# fields itself with has_paper_trail, as it may track others too.
module TrackableTitleAndDescription
  extend ActiveSupport::Concern
  include FieldEditTracker

  def title_edited?
    field_edited?('title')
  end

  def description_edited?
    field_edited?('description')
  end
end
