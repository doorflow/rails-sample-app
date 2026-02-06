# frozen_string_literal: true

# Background job for deleting a person from DoorFlow.
# This avoids blocking web requests with external API calls.
class DeletePersonJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on DoorflowPersonService::DeleteError, wait: :polynomially_longer, attempts: 3
  retry_on DoorflowPersonService::NotConnectedError, wait: 5.minutes, attempts: 2

  # @param doorflow_person_id [Integer] the DoorFlow person ID to delete
  # @param member_email [String] for logging purposes
  def perform(doorflow_person_id, member_email: nil)
    client = DoorflowClientBuilder.build
    unless client
      Rails.logger.warn "[DeletePersonJob] DoorFlow not connected, will retry"
      raise DoorflowPersonService::NotConnectedError, "DoorFlow not connected"
    end

    service = DoorflowPersonService.new(client: client)
    service.delete_person(doorflow_person_id)

    Rails.logger.info "[DeletePersonJob] Successfully deleted DoorFlow person #{doorflow_person_id} (#{member_email})"
  end
end
