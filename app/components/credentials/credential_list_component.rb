# frozen_string_literal: true

# Displays a person's credentials (access cards, PINs, etc.) from DoorFlow.
# Shows credential type, identifier, and status.
# Matches TypeScript CredentialList.tsx styling.
module Credentials
  class CredentialListComponent < ViewComponent::Base
    def initialize(credentials:, person_id: nil)
      @credentials = credentials || []
      @person_id = person_id
    end

    # Determine credential category from label
    def credential_category(label)
      return "card" unless label

      lower = label.downcase
      return "pin" if lower.include?("pin")
      return "mobile" if lower.include?("mobile") || lower.include?("passflow") || lower.include?("wallet") || lower.include?("hid")

      "card"
    end

    def credential_icon(label)
      case credential_category(label)
      when "pin"
        "hash"
      when "mobile"
        "smartphone"
      else
        "credit-card"
      end
    end

    def icon_container_classes(label)
      base = "w-10 h-10 rounded-lg flex items-center justify-center"
      case credential_category(label)
      when "mobile"
        "#{base} bg-blue-100 text-blue-600"
      else
        "#{base} bg-green-100 text-green-600"
      end
    end

    def status_badge_classes(status)
      base = "text-xs px-2 py-0.5 rounded-full font-bold"
      case status&.downcase
      when "active"
        "#{base} bg-green-100 text-green-700"
      when "invited"
        "#{base} bg-yellow-100 text-yellow-700"
      when "revoking", "revoked", "inactive"
        "#{base} bg-red-100 text-red-700"
      else
        "#{base} bg-gray-100 text-gray-600"
      end
    end

    # Get display info for credential
    def credential_display_value(credential)
      # PassFlow credentials have URL
      if credential[:url].present?
        wallet_type = credential[:wallet_type]
        if wallet_type.present?
          wallet_name = wallet_type == "apple" ? "Apple" : "Google"
          "Added to #{wallet_name} Wallet"
        else
          "Invitation sent"
        end
      # HID Mobile credentials have status but no value
      elsif credential[:status].present? && credential[:value].blank?
        case credential[:status]
        when "invited" then "Invitation sent"
        when "active" then "Active on device"
        when "revoking" then "Being revoked"
        when "revoked" then "Revoked"
        else credential[:status]
        end
      # Card/PIN credentials have a value
      elsif credential[:value].present?
        value = credential[:value]
        value.include?("*") ? value : "****#{value[-4..]}"
      else
        "No value"
      end
    end

    attr_reader :credentials, :person_id
  end
end
