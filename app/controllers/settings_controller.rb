# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    @connection_status = doorflow_status
    @teams = CrmTeam.all
    @groups = fetch_groups
    @credential_types = fetch_credential_types
    @member_stats = compute_member_stats
  end

  def refresh
    # Clear cached data so it's re-fetched from DoorFlow
    Rails.cache.delete("doorflow_groups")
    Rails.cache.delete("doorflow_credential_types")
    redirect_to settings_path, notice: "Cached data refreshed"
  end

  private

  def fetch_groups
    return [] unless doorflow_connected?

    Rails.cache.fetch("doorflow_groups", expires_in: 5.minutes) do
      doorflow.groups.list.data.map(&:attributes)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch groups: #{e.message}"
    []
  end

  def fetch_credential_types
    return [] unless doorflow_connected?

    Rails.cache.fetch("doorflow_credential_types", expires_in: 5.minutes) do
      doorflow.credential_types.list.data.map(&:attributes)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch credential types: #{e.message}"
    []
  end

  def compute_member_stats
    total = CrmMember.count
    linked = CrmMember.where.not(doorflow_person_id: nil).count
    {
      total: total,
      linked: linked,
      unlinked: total - linked
    }
  end
end
