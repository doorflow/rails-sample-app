# frozen_string_literal: true

# Service for managing DoorFlow person operations.
# Encapsulates all DoorFlow API interactions related to people, credentials, and groups.
class DoorflowPersonService
  class Error < StandardError; end
  class NotConnectedError < Error; end
  class SyncError < Error; end
  class DeleteError < Error; end

  attr_reader :client

  # @param client [DoorFlow::Client] the DoorFlow client instance
  def initialize(client:)
    @client = client
  end

  # Check if we have a valid client connection
  def connected?
    return false unless client

    client.authenticated?
  rescue StandardError
    false
  end

  # Fetch credentials for a person
  # @param person_id [Integer] the DoorFlow person ID
  # @return [Array<Hash>] array of credential attributes
  def fetch_credentials(person_id)
    return [] unless person_id.present? && connected?

    client.credentials.list_for_person(person_id).map(&:attributes)
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to fetch credentials for person #{person_id}: #{e.message}"
    raise Error, "Failed to fetch credentials: #{e.message}"
  end

  # Fetch all groups from DoorFlow (cached)
  # @return [Array<Hash>] array of group attributes
  def fetch_groups
    return [] unless connected?

    Rails.cache.fetch("doorflow_groups", expires_in: 5.minutes) do
      client.groups.list.data.map(&:attributes)
    end
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to fetch groups: #{e.message}"
    raise Error, "Failed to fetch groups: #{e.message}"
  end

  # Fetch all credential types from DoorFlow (cached)
  # @return [Array<Hash>] array of credential type attributes
  def fetch_credential_types
    return [] unless connected?

    Rails.cache.fetch("doorflow_credential_types", expires_in: 5.minutes) do
      client.credential_types.list.data.map(&:attributes)
    end
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to fetch credential types: #{e.message}"
    raise Error, "Failed to fetch credential types: #{e.message}"
  end

  # Create a person in DoorFlow and link to the member
  # @param member [CrmMember] the member to create in DoorFlow
  # @param include_image [Boolean] whether to include image
  # @return [Integer] the DoorFlow person ID
  # @raise [NotConnectedError] if not connected to DoorFlow
  # @raise [SyncError] if creation fails
  def create_person(member, include_image: false)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?
    raise ArgumentError, "Member is already linked to DoorFlow" if member.linked?

    person = client.people.create(member.to_doorflow_params(include_image: include_image))

    Rails.logger.info "[DoorflowPersonService] Created DoorFlow person #{person.id} for member #{member.id}"
    person.id
  rescue NotConnectedError, ArgumentError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to create person for member #{member.id}: #{e.message}"
    raise SyncError, "Failed to create person in DoorFlow: #{e.message}"
  end

  # Sync a member's data to DoorFlow
  # @param member [CrmMember] the member to sync
  # @param include_image [Boolean] whether to include image in sync
  # @raise [NotConnectedError] if not connected to DoorFlow
  # @raise [ArgumentError] if member is not linked
  # @raise [SyncError] if sync fails
  def sync_member(member, include_image: false)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?
    raise ArgumentError, "Member is not linked to DoorFlow" unless member.linked?

    person = client.people.retrieve(member.doorflow_person_id)
    person.update(member.to_doorflow_params(include_image: include_image))

    Rails.logger.info "[DoorflowPersonService] Synced member #{member.id} to DoorFlow person #{member.doorflow_person_id}"
    true
  rescue NotConnectedError, ArgumentError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to sync member #{member.id}: #{e.message}"
    raise SyncError, "Failed to sync member to DoorFlow: #{e.message}"
  end

  # Update a person's group assignments in DoorFlow
  # @param person_id [Integer] the DoorFlow person ID
  # @param group_ids [Array<Integer>] the group IDs to assign
  # @raise [NotConnectedError] if not connected to DoorFlow
  # @raise [SyncError] if update fails
  def update_person_groups(person_id, group_ids)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?

    person = client.people.retrieve(person_id)
    person.update(group_ids: group_ids)

    Rails.logger.info "[DoorflowPersonService] Updated groups for person #{person_id}: #{group_ids}"
    true
  rescue NotConnectedError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to update groups for person #{person_id}: #{e.message}"
    raise SyncError, "Failed to update person groups: #{e.message}"
  end

  # Delete a person from DoorFlow
  # @param person_id [Integer] the DoorFlow person ID
  # @raise [NotConnectedError] if not connected to DoorFlow
  # @raise [DeleteError] if delete fails
  def delete_person(person_id)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?

    client.people.delete(person_id)

    Rails.logger.info "[DoorflowPersonService] Deleted DoorFlow person #{person_id}"
    true
  rescue NotConnectedError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to delete person #{person_id}: #{e.message}"
    raise DeleteError, "Failed to delete person from DoorFlow: #{e.message}"
  end

  # Create a credential for a person
  # @param person_id [Integer] the DoorFlow person ID
  # @param credential_type_id [Integer] the credential type ID
  # @param value [String] the credential value
  # @return [Hash] the created credential attributes
  def create_credential(person_id:, credential_type_id:, value:)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?

    credential = client.credentials.create(
      person_id: person_id,
      credential_type_id: credential_type_id,
      value: value
    )

    Rails.logger.info "[DoorflowPersonService] Created credential for person #{person_id}"
    credential.attributes
  rescue NotConnectedError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to create credential: #{e.message}"
    raise Error, "Failed to create credential: #{e.message}"
  end

  # Delete a credential
  # @param credential_id [Integer] the credential ID
  def delete_credential(credential_id)
    raise NotConnectedError, "Not connected to DoorFlow" unless connected?

    client.credentials.delete(credential_id)

    Rails.logger.info "[DoorflowPersonService] Deleted credential #{credential_id}"
    true
  rescue NotConnectedError
    raise
  rescue StandardError => e
    Rails.logger.error "[DoorflowPersonService] Failed to delete credential #{credential_id}: #{e.message}"
    raise Error, "Failed to delete credential: #{e.message}"
  end
end
