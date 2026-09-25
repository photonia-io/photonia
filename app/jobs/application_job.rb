# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Wait for the enqueuing transaction to commit (was the global 7.2 default; Rails 8 makes it per job)
  self.enqueue_after_transaction_commit = true

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
