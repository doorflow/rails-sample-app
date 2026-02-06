# frozen_string_literal: true

# Visual indicator showing whether a CRM member is linked to a DoorFlow person.
# Displays as a pill-shaped badge with icon and text.
module Members
  class SyncStatusBadgeComponent < ViewComponent::Base
    def initialize(doorflow_person_id:)
      @doorflow_person_id = doorflow_person_id
    end

    def linked?
      @doorflow_person_id.present?
    end

    def badge_classes
      if linked?
        "inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-green-50 text-green-700"
      else
        "inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gray-100 text-gray-600"
      end
    end

    def dot_classes
      if linked?
        "w-2 h-2 rounded-full bg-green-400 shadow-[0_0_6px_rgba(74,222,128,0.5)]"
      else
        "w-2 h-2 rounded-full bg-gray-400"
      end
    end

    attr_reader :doorflow_person_id
  end
end
