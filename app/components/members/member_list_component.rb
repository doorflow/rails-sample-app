# frozen_string_literal: true

# Displays a filterable list of CRM members.
# Includes filter buttons and optional create form toggle.
# Matches TypeScript MemberList.tsx styling.
module Members
  class MemberListComponent < ViewComponent::Base
    def initialize(members:, filter: "all")
      @members = members
      @filter = filter
    end

    def filtered_members
      case @filter
      when "linked"
        @members.linked
      when "unlinked"
        @members.unlinked
      else
        @members
      end
    end

    def filter_button_classes(filter_value)
      base = "px-4 py-2 rounded-full text-sm font-semibold transition-all"
      case filter_value
      when "all"
        if @filter == "all"
          "#{base} bg-purple-600 text-white"
        else
          "#{base} border border-gray-300 text-gray-600 hover:bg-gray-50"
        end
      when "linked"
        if @filter == "linked"
          "#{base} bg-green-600 text-white"
        else
          "#{base} border border-gray-300 text-gray-600 hover:bg-gray-50"
        end
      when "unlinked"
        if @filter == "unlinked"
          "#{base} bg-gray-600 text-white"
        else
          "#{base} border border-gray-300 text-gray-600 hover:bg-gray-50"
        end
      else
        "#{base} border border-gray-300 text-gray-600 hover:bg-gray-50"
      end
    end

    def filters
      [
        { value: "all", label: "All Members", count: @members.count },
        { value: "linked", label: "Linked to DoorFlow", count: @members.linked.count },
        { value: "unlinked", label: "Not Linked", count: @members.unlinked.count }
      ]
    end

    def member_count_text
      count = filtered_members.count
      "Showing #{count} member#{'s' unless count == 1}"
    end

    attr_reader :members, :filter
  end
end
