# frozen_string_literal: true

# Concern for tracking changes of the body field
module TrackableBody
  extend ActiveSupport::Concern
  include FieldEditTracker

  included do
    has_paper_trail only: %i[body]
  end

  def body_edited?
    field_edited?('body')
  end
end
