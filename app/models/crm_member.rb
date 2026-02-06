# frozen_string_literal: true

# A member in the local CRM system.
# Members can be linked to DoorFlow people for access control integration.
class CrmMember < ApplicationRecord
  has_and_belongs_to_many :crm_teams

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :membership_type, inclusion: { in: %w[standard premium] }

  # Scopes
  scope :linked, -> { where.not(doorflow_person_id: nil) }
  scope :unlinked, -> { where(doorflow_person_id: nil) }
  scope :premium, -> { where(membership_type: "premium") }
  scope :standard, -> { where(membership_type: "standard") }

  # Check if this member is linked to a DoorFlow person
  def linked?
    doorflow_person_id.present?
  end

  # Get the full name
  def full_name
    "#{first_name} #{last_name}"
  end

  # Get initials for avatar fallback
  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  # Check if this is a premium member
  def premium?
    membership_type == "premium"
  end

  # Get the DoorFlow group IDs this member should belong to
  # (based on their team memberships with mapped DoorFlow groups)
  def doorflow_group_ids
    crm_teams.where.not(doorflow_group_id: nil).pluck(:doorflow_group_id)
  end

  # Get the full path to the member's image file
  def image_path
    return nil unless image.present?

    Rails.root.join("public", "images", "members", image)
  end

  # Get the URL for the member's image (for display in views)
  def image_url
    return nil unless image.present?

    "/images/members/#{image}"
  end

  # Convert to attributes for DoorFlow API
  # The SDK handles image_file conversion to data URI format automatically
  #
  # NOTE: By default, image is only included when it has changed (saved_change_to_image?)
  # to avoid sending large base64 data on every update. Pass include_image: true to
  # force inclusion (e.g., when creating a new person in DoorFlow).
  def to_doorflow_params(include_image: false)
    params = {
      first_name: first_name,
      last_name: last_name,
      email: email,
      telephone: phone,
      mobile: mobile,
      department: department,
      job_title: job_title,
      notes: notes,
      custom_1: membership_type,
      system_id: id.to_s,
      group_ids: doorflow_group_ids
    }

    # Only include image if it was just changed or explicitly requested
    # This avoids sending large base64 payloads on every update
    should_include_image = include_image || saved_change_to_image?
    if should_include_image && image.present? && image_path && File.exist?(image_path)
      params[:image_file] = image_path.to_s
    end

    params.compact
  end
end
