# frozen_string_literal: true

# A team in the local CRM system.
# Teams can be mapped to DoorFlow groups to control access permissions.
class CrmTeam < ApplicationRecord
  has_and_belongs_to_many :crm_members

  validates :name, presence: true

  # Check if this team is mapped to a DoorFlow group
  def mapped?
    doorflow_group_id.present?
  end

  # Get team members who are linked to DoorFlow
  def linked_members
    crm_members.where.not(doorflow_person_id: nil)
  end

  # Get team members who are not yet linked to DoorFlow
  def unlinked_members
    crm_members.where(doorflow_person_id: nil)
  end
end
