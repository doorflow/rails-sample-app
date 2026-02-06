# frozen_string_literal: true

module Api
  class ResetController < ApplicationController
    def create
      # Reset members to demo data
      CrmMember.delete_all
      seed_members

      # Reset teams to demo data
      CrmTeam.delete_all
      seed_teams

      # Disconnect from DoorFlow
      client = DoorflowClient.new
      client.disconnect if client.connected?

      redirect_to settings_path, notice: "Application reset to demo state"
    end

    private

    def seed_members
      [
        { name: "Alice Smith", email: "alice.smith@example.com", membership_type: "premium", phone: "+1-555-0101" },
        { name: "Bob Johnson", email: "bob.johnson@example.com", membership_type: "standard", phone: "+1-555-0102" },
        { name: "Carol Williams", email: "carol.williams@example.com", membership_type: "premium", phone: "+1-555-0103" },
        { name: "Eva Martinez", email: "eva.martinez@example.com", membership_type: "standard", phone: nil }
      ].each do |attrs|
        CrmMember.create!(attrs)
      end
    end

    def seed_teams
      [
        { name: "Engineering", description: "Software development team" },
        { name: "Sales", description: "Sales and business development" },
        { name: "Operations", description: "Operations and support" }
      ].each do |attrs|
        CrmTeam.create!(attrs)
      end
    end
  end
end
