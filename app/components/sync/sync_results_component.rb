# frozen_string_literal: true

# Displays the results of a member sync operation.
# Shows stats (created, updated, matched, failed) and optional details.
module Sync
  class SyncResultsComponent < ViewComponent::Base
    def initialize(results:, is_dry_run: false)
      @results = results || {}
      @is_dry_run = is_dry_run
    end

    def stats
      [
        { label: "Created", value: @results[:created]&.length || 0, color: "green" },
        { label: "Updated", value: @results[:updated]&.length || 0, color: "blue" },
        { label: "Matched", value: @results[:matched]&.length || 0, color: "purple" },
        { label: "Failed", value: @results[:failed]&.length || 0, color: "red" }
      ]
    end

    def stat_box_classes(color)
      bg_colors = {
        "green" => "bg-green-50",
        "blue" => "bg-blue-50",
        "purple" => "bg-purple-50",
        "red" => "bg-red-50"
      }
      text_colors = {
        "green" => "text-green-700",
        "blue" => "text-blue-700",
        "purple" => "text-purple-700",
        "red" => "text-red-700"
      }
      "rounded-xl p-4 #{bg_colors[color]} #{text_colors[color]}"
    end

    def total_processed
      stats.sum { |s| s[:value] }
    end

    def has_failures?
      (@results[:failed]&.length || 0) > 0
    end

    def dry_run?
      @is_dry_run
    end

    attr_reader :results
  end
end
