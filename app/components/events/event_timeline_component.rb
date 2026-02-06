# frozen_string_literal: true

# Displays recent access events with a clean timeline design.
# Matches the TypeScript EventTimeline.tsx component.
module Events
  class EventTimelineComponent < ViewComponent::Base
    def initialize(events:, loading: false, error: nil)
      @events = events || []
      @loading = loading
      @error = error
    end

    def loading?
      @loading
    end

    def error?
      @error.present?
    end

    def empty?
      @events.empty?
    end

    def event_info(event_code)
      case event_code
      when 10..18, 70
        { label: "Access Granted", color: "green", icon: "check" }
      when 20..29, 71..73
        { label: "Access Denied", color: "red", icon: "x" }
      when 40..42
        { label: "Auto-Unlock", color: "blue", icon: "unlock" }
      when 90..91
        { label: "Tamper Alert", color: "orange", icon: "alert-triangle" }
      else
        { label: "Event", color: "gray", icon: "circle" }
      end
    end

    def dot_classes(color)
      bg_colors = {
        "green" => "bg-green-100 text-green-600",
        "red" => "bg-red-100 text-red-600",
        "blue" => "bg-blue-100 text-blue-600",
        "orange" => "bg-orange-100 text-orange-600",
        "gray" => "bg-gray-100 text-gray-600"
      }
      "w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm z-10 #{bg_colors[color]}"
    end

    def badge_classes(color)
      bg_colors = {
        "green" => "bg-green-100 text-green-700",
        "red" => "bg-red-100 text-red-700",
        "blue" => "bg-blue-100 text-blue-700",
        "orange" => "bg-orange-100 text-orange-700",
        "gray" => "bg-gray-100 text-gray-700"
      }
      "px-2 py-0.5 rounded-full text-xs font-bold #{bg_colors[color]}"
    end

    def format_timestamp(timestamp)
      return "" unless timestamp
      Time.parse(timestamp.to_s).strftime("%b %d, %Y %l:%M %p")
    rescue
      timestamp.to_s
    end

    attr_reader :events, :error
  end
end
