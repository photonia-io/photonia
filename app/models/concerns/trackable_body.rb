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

  def body_last_edited_at
    # Use preloaded versions if available
    relevant_versions = versions.select do |version|
      version.event == 'update' && version.object_changes.to_s.include?('"body" =>')
    end

    last_body_version = relevant_versions.last
    last_body_version&.created_at
  end
end
