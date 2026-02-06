# frozen_string_literal: true

# Service for synchronizing CRM members with DoorFlow people.
# Handles matching, creating, and updating people in DoorFlow.
class MemberSyncService
  # Initialize the sync service
  # @param client [DoorFlow::Client] the DoorFlow client to use for API calls
  def initialize(client:)
    @client = client
  end

  # Sync members to DoorFlow
  # @param members [ActiveRecord::Relation] Members to sync
  # @param dry_run [Boolean] If true, don't make changes
  # @return [Hash] Results with :created, :updated, :matched, :failed arrays
  def sync(members, dry_run: false)
    results = {
      created: [],
      updated: [],
      matched: [],
      failed: []
    }

    members.find_each do |member|
      sync_member(member, results, dry_run: dry_run)
    rescue StandardError => e
      Rails.logger.error "Failed to sync member #{member.id}: #{e.message}"
      results[:failed] << {
        id: member.id,
        email: member.email,
        name: member.full_name,
        error: e.message
      }
    end

    results
  end

  # Sync a single member
  def sync_single(member, dry_run: false)
    results = {
      created: [],
      updated: [],
      matched: [],
      failed: []
    }

    sync_member(member, results, dry_run: dry_run)
    results
  end

  private

  def sync_member(member, results, dry_run:)
    # Check if already linked
    if member.doorflow_person_id.present?
      update_existing_person(member, results, dry_run: dry_run)
    else
      find_or_create_person(member, results, dry_run: dry_run)
    end
  end

  def find_or_create_person(member, results, dry_run:)
    # Try to find by email
    existing = find_person_by_email(member.email)

    if existing
      # Found existing person - link and update
      link_and_update(member, existing, results, dry_run: dry_run)
    else
      # Create new person
      create_person(member, results, dry_run: dry_run)
    end
  end

  def find_person_by_email(email)
    result = @client.people.list(email: email)
    result.data.first
  end

  def link_and_update(member, existing_person, results, dry_run:)
    person_id = existing_person.id

    unless dry_run
      # Link the member to the DoorFlow person
      member.update!(doorflow_person_id: person_id)

      # Update the person with current member data (include image on first link)
      existing_person.update(member.to_doorflow_params(include_image: true))
    end

    results[:matched] << {
      id: member.id,
      email: member.email,
      name: member.full_name,
      doorflow_person_id: person_id
    }
  end

  def create_person(member, results, dry_run:)
    if dry_run
      results[:created] << {
        id: member.id,
        email: member.email,
        name: member.full_name,
        doorflow_person_id: nil
      }
    else
      # Create person in DoorFlow (include image on creation)
      person = @client.people.create(member.to_doorflow_params(include_image: true))
      person_id = person.id

      # Link the member
      member.update!(doorflow_person_id: person_id)

      results[:created] << {
        id: member.id,
        email: member.email,
        name: member.full_name,
        doorflow_person_id: person_id
      }
    end
  end

  def update_existing_person(member, results, dry_run:)
    unless dry_run
      person = @client.people.retrieve(member.doorflow_person_id)
      person.update(member.to_doorflow_params)
    end

    results[:updated] << {
      id: member.id,
      email: member.email,
      name: member.full_name,
      doorflow_person_id: member.doorflow_person_id
    }
  end
end
