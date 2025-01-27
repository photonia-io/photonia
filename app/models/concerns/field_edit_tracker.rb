# frozen_string_literal: true

# Tracking Paper Trail edits to fields
module FieldEditTracker
  private

  def field_edited?(field)
    versions.offset(1).any? do |version|
      changes = version.object_changes
      changes && changes[field].present?
    end
  end
end
