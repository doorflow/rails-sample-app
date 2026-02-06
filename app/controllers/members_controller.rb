# frozen_string_literal: true

class MembersController < ApplicationController
  def index
    @members = CrmMember.includes(:crm_teams).order(:last_name, :first_name)
    @filter = params[:filter] || "all"
    @connected = doorflow_connected?
  end

  def show
    @member = CrmMember.includes(:crm_teams).find(params[:id])
    @teams = CrmTeam.all
    @connected = doorflow_connected?
    load_doorflow_data_for_show
  end

  def new
    @member = CrmMember.new
    @teams = CrmTeam.all
  end

  def create
    @member = CrmMember.new(member_params)

    if @member.save
      enqueue_link_to_doorflow(@member)
      redirect_to member_path(@member), notice: "Member created successfully. DoorFlow sync queued."
    else
      @teams = CrmTeam.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @member = CrmMember.find(params[:id])
    @teams = CrmTeam.all
  end

  def update
    @member = CrmMember.find(params[:id])

    if @member.update(member_params)
      enqueue_sync_if_linked(@member)
      redirect_to member_path(@member), notice: "Member updated successfully. DoorFlow sync queued."
    else
      @teams = CrmTeam.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @member = CrmMember.find(params[:id])

    # Capture DoorFlow person ID before destroying
    doorflow_person_id = @member.doorflow_person_id
    member_email = @member.email

    @member.destroy

    enqueue_delete_if_was_linked(doorflow_person_id, member_email)
    redirect_to members_path, notice: "Member deleted successfully."
  end

  private

  def member_params
    permitted = params.require(:crm_member).permit(
      :first_name, :last_name, :email, :phone, :mobile,
      :department, :job_title, :notes, :membership_type,
      :image_file,
      crm_team_ids: []
    )

    # Handle image upload
    if permitted[:image_file].present?
      uploaded_file = permitted.delete(:image_file)
      filename = "#{SecureRandom.hex(8)}#{File.extname(uploaded_file.original_filename)}"
      filepath = Rails.root.join("public", "images", "members", filename)

      # Ensure directory exists
      FileUtils.mkdir_p(File.dirname(filepath))

      # Save the file
      File.binwrite(filepath, uploaded_file.read)

      permitted[:image] = filename
    end

    permitted
  end

  def doorflow_service
    @doorflow_service ||= DoorflowPersonService.new(client: doorflow)
  end

  def load_doorflow_data_for_show
    @credentials = []
    @credential_types = []
    @groups = []

    return unless doorflow_connected?

    @credentials = doorflow_service.fetch_credentials(@member.doorflow_person_id)
    @credential_types = doorflow_service.fetch_credential_types
    @groups = doorflow_service.fetch_groups
  rescue DoorflowPersonService::Error => e
    flash.now[:alert] = "Could not load some DoorFlow data: #{e.message}"
  end

  def enqueue_link_to_doorflow(member)
    return unless doorflow_connected?

    LinkMemberJob.perform_later(member.id)
  end

  def enqueue_sync_if_linked(member)
    return unless member.linked? && doorflow_connected?

    SyncMemberJob.perform_later(member.id)
  end

  def enqueue_delete_if_was_linked(doorflow_person_id, member_email)
    return unless doorflow_person_id.present? && doorflow_connected?

    DeletePersonJob.perform_later(doorflow_person_id, member_email: member_email)
  end
end
