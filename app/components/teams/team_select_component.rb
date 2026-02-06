# frozen_string_literal: true

# Multi-select component for assigning CRM teams to a member.
# Displays teams as a checkbox grid with orange selection styling.
# Matches TypeScript TeamSelect.tsx component styling.
module Teams
  class TeamSelectComponent < ViewComponent::Base
    def initialize(teams:, selected_team_ids: [])
      @teams = teams
      @selected_team_ids = Array(selected_team_ids).map(&:to_i)
    end

    def selected?(team_id)
      @selected_team_ids.include?(team_id.to_i)
    end

    def card_classes(team_id)
      base = "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200"
      if selected?(team_id)
        "#{base} border-orange-400 bg-orange-50 hover:border-orange-500"
      else
        "#{base} border-gray-200 bg-white hover:border-gray-300 hover:-translate-y-0.5"
      end
    end

    def team_name_classes(team_id)
      if selected?(team_id)
        "font-semibold text-orange-700 text-sm"
      else
        "font-semibold text-gray-700 text-sm"
      end
    end

    def checkbox_container_classes(team_id)
      base = "w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0"
      if selected?(team_id)
        "#{base} border-orange-500 bg-orange-500"
      else
        "#{base} border-gray-300 bg-white"
      end
    end

    attr_reader :teams, :selected_team_ids
  end
end
