# frozen_string_literal: true

# Background job for syncing a member to DoorFlow.
# This avoids blocking web requests with external API calls.
class SyncMemberJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on DoorflowPersonService::SyncError, wait: :polynomially_longer, attempts: 3
  retry_on DoorflowPersonService::NotConnectedError, wait: 5.minutes, attempts: 2

  # Don't retry if the member no longer exists
  discard_on ActiveRecord::RecordNotFound

  # @param member_id [Integer] the CRM member ID to sync
  # @param include_image [Boolean] whether to include the image in sync
  def perform(member_id, include_image: false)
    member = CrmMember.find(member_id)

    unless member.linked?
      Rails.logger.info "[SyncMemberJob] Member #{member_id} is not linked, skipping sync"
      return
    end

    client = DoorflowClientBuilder.build
    unless client
      Rails.logger.warn "[SyncMemberJob] DoorFlow not connected, will retry"
      raise DoorflowPersonService::NotConnectedError, "DoorFlow not connected"
    end

    service = DoorflowPersonService.new(client: client)
    service.sync_member(member, include_image: include_image)

    Rails.logger.info "[SyncMemberJob] Successfully synced member #{member_id}"
  end
end
