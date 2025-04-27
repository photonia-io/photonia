# frozen_string_literal: true

# Concern for tracking changes of the title and description fields
module TrackableTitleAndDescription
  extend ActiveSupport::Concern
  include FieldEditTracker

  included do
    has_paper_trail only: %i[title description]
  end

  def title_edited?
    field_edited?('title')
  end

  def description_edited?
    field_edited?('description')
  end
end
