# frozen_string_literal: true

# Background job for syncing all team members' group assignments to DoorFlow.
# Used when a team's DoorFlow group mapping changes.
class SyncTeamMembersJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on DoorflowPersonService::NotConnectedError, wait: 5.minutes, attempts: 2

  # Don't retry if the team no longer exists
  discard_on ActiveRecord::RecordNotFound

  # @param team_id [Integer] the team ID whose members should be synced
  def perform(team_id)
    team = CrmTeam.find(team_id)

    client = DoorflowClientBuilder.build
    unless client
      Rails.logger.warn "[SyncTeamMembersJob] DoorFlow not connected, will retry"
      raise DoorflowPersonService::NotConnectedError, "DoorFlow not connected"
    end

    service = DoorflowPersonService.new(client: client)
    results = { synced: 0, failed: 0, errors: [] }

    team.linked_members.find_each do |member|
      service.update_person_groups(member.doorflow_person_id, member.doorflow_group_ids)
      results[:synced] += 1
    rescue DoorflowPersonService::SyncError => e
      results[:failed] += 1
      results[:errors] << "#{member.full_name}: #{e.message}"
      Rails.logger.error "[SyncTeamMembersJob] Failed to sync member #{member.id}: #{e.message}"
    end

    Rails.logger.info "[SyncTeamMembersJob] Team #{team_id} sync complete: #{results[:synced]} synced, #{results[:failed]} failed"
  end
end
