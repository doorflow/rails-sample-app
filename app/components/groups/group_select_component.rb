# frozen_string_literal: true

# Multi-select component for assigning DoorFlow groups to a person.
# Displays groups as a checkbox grid with purple selection styling.
module Groups
  class GroupSelectComponent < ViewComponent::Base
    def initialize(groups:, selected_group_ids: [], person_id: nil)
      @groups = groups
      @selected_group_ids = Array(selected_group_ids).map(&:to_i)
      @person_id = person_id
    end

    def selected?(group_id)
      @selected_group_ids.include?(group_id.to_i)
    end

    def card_classes(group_id)
      base = "border-2 rounded-xl p-4 cursor-pointer transition-all"
      if selected?(group_id)
        "#{base} border-purple-400 bg-purple-50"
      else
        "#{base} border-gray-200 bg-white hover:-translate-y-0.5"
      end
    end

    attr_reader :groups, :selected_group_ids, :person_id
  end
end
