# frozen_string_literal: true

# Usage examples:
# Default values: min_support=2, min_confidence=0.3
#   rake related_tags:precompute
#   rake related_tags:precompute[min_support=3,min_confidence=0.4]
#   rake related_tags:compute_now
#   rake related_tags:compute_now[min_support=5,min_confidence=0.5
namespace :related_tags do
  desc 'Enqueue precomputation job (optional args: min_support=2, min_confidence=0.3)'
  task :precompute, %i[min_support min_confidence] => :environment do |_t, args|
    min_support = (args[:min_support] || 2).to_i
    min_confidence = (args[:min_confidence] || 0.3).to_f

    PrecomputeRelatedTagsJob.perform_later(min_support: min_support, min_confidence: min_confidence)
    puts "Enqueued PrecomputeRelatedTagsJob with min_support=#{min_support}, min_confidence=#{min_confidence}"
  end

  desc 'Run precomputation inline (blocking). Useful locally. (optional args: min_support=2, min_confidence=0.3)'
  task :compute_now, %i[min_support min_confidence] => :environment do |_t, args|
    min_support = (args[:min_support] || 2).to_i
    min_confidence = (args[:min_confidence] || 0.3).to_f

    PrecomputeRelatedTagsJob.perform_now(min_support: min_support, min_confidence: min_confidence)
    puts "Completed PrecomputeRelatedTagsJob with min_support=#{min_support}, min_confidence=#{min_confidence}"
  end
end
