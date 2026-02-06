# frozen_string_literal: true

# Background job for creating a member in DoorFlow and linking them.
# Called automatically when a new member is created.
class LinkMemberJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on DoorflowPersonService::SyncError, wait: :polynomially_longer, attempts: 3
  retry_on DoorflowPersonService::NotConnectedError, wait: 5.minutes, attempts: 2

  # Don't retry if the member no longer exists
  discard_on ActiveRecord::RecordNotFound

  # @param member_id [Integer] the CRM member ID to link
  def perform(member_id)
    member = CrmMember.find(member_id)

    # Skip if already linked
    if member.linked?
      Rails.logger.info "[LinkMemberJob] Member #{member_id} is already linked, skipping"
      return
    end

    client = DoorflowClientBuilder.build
    unless client
      Rails.logger.warn "[LinkMemberJob] DoorFlow not connected, will retry"
      raise DoorflowPersonService::NotConnectedError, "DoorFlow not connected"
    end

    service = DoorflowPersonService.new(client: client)
    doorflow_person_id = service.create_person(member)

    # Update the member with the DoorFlow person ID
    member.update!(doorflow_person_id: doorflow_person_id)

    Rails.logger.info "[LinkMemberJob] Successfully linked member #{member_id} to DoorFlow person #{doorflow_person_id}"
  end
end
