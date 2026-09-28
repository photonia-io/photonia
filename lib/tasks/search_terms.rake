# frozen_string_literal: true

namespace :search_terms do
  desc 'Enqueue nightly precomputation of SearchTerm suggestion words'
  task precompute: :environment do
    PrecomputeSearchTermsJob.perform_later
    puts 'Enqueued PrecomputeSearchTermsJob'
  end

  desc 'Run precomputation inline (blocking). Useful locally.'
  task compute_now: :environment do
    PrecomputeSearchTermsJob.perform_now
    puts 'Completed PrecomputeSearchTermsJob'
  end
end
