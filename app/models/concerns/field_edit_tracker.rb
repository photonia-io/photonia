# frozen_string_literal: true

# Tracking Paper Trail edits to fields
module FieldEditTracker
  private

  def field_edited?(field)
    # Use preloaded versions if available
    preloaded_versions = versions.to_a.drop(1) # Drop the first version (initial creation)
    preloaded_versions.any? do |version|
      changes = version.object_changes
      changes && changes[field].present?
    end
  end
end
