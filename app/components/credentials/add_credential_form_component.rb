# frozen_string_literal: true

# Form component for adding new credentials to a person.
# Matches the TypeScript AddCredentialForm.tsx component styling.
module Credentials
  class AddCredentialFormComponent < ViewComponent::Base
    def initialize(person:, credential_types:, existing_credentials: [])
      @person = person
      @credential_types = credential_types || []
      @existing_credentials = existing_credentials || []
    end

    def credential_category(type)
      label = (type[:label] || type["label"] || "").downcase
      slug = (type[:slug] || type["slug"] || "").downcase

      # PIN types
      return "pin" if label.include?("pin") || slug.include?("pin")

      # Mobile types - invitation-based
      mobile_keywords = %w[mobile hid passflow apple google wallet]
      return "mobile" if mobile_keywords.any? { |kw| label.include?(kw) || slug.include?(kw) }

      # Default to card
      "card"
    end

    def credential_icon(category)
      case category
      when "pin" then "hash"
      when "mobile" then "smartphone"
      else "credit-card"
      end
    end

    def type_already_assigned?(type_id)
      existing_type_ids.include?(type_id)
    end

    def existing_type_ids
      @existing_type_ids ||= @existing_credentials.map { |c| c[:credential_type_id] || c["credentialTypeId"] }.compact
    end

    def person_id
      @person[:id] || @person["id"] || @person.try(:id)
    end

    attr_reader :person, :credential_types, :existing_credentials
  end
end
