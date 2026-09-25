# frozen_string_literal: true

# Monkeypatching ActsAsTaggableOn::Tagging class
ActsAsTaggableOn::Tagging.class_eval do
  after_commit :refresh_photo_tsv

  # Tag writes never UPDATE photos, so the tsv trigger never fires
  def refresh_photo_tsv
    return unless taggable_type == 'Photo'

    # rubocop:disable-next Rails/SkipsModelValidations
    Photo.unscoped.where(id: taggable_id).touch_all
  end
end
