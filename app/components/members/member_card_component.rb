# frozen_string_literal: true

# Displays a member as a card/row item in the member list.
# Shows avatar, name, email, membership type, and sync status.
# Matches TypeScript MemberCard.tsx compact row styling.
module Members
  class MemberCardComponent < ViewComponent::Base
    def initialize(member:)
      @member = member
    end

    def avatar_url
      @member.image_url || "/images/members/default.jpg"
    end

    def avatar_fallback
      @member.initials
    end

    def avatar_bg_classes
      if @member.premium?
        "bg-purple-100 text-purple-600"
      else
        "bg-gray-100 text-gray-600"
      end
    end

    def membership_badge_classes
      if @member.premium?
        "px-2 py-0.5 text-xs font-medium rounded-full bg-purple-50 text-purple-600 capitalize"
      else
        "px-2 py-0.5 text-xs font-medium rounded-full bg-gray-100 text-gray-500 capitalize"
      end
    end

    def card_classes
      "block bg-white px-4 py-3 rounded-lg border border-gray-100 hover:bg-gray-50 hover:border-purple-200 transition-all duration-150 cursor-pointer"
    end

    attr_reader :member
  end
end
