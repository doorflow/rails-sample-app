# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @teams = CrmTeam.includes(:crm_members).order(:name)
    @groups = load_groups
  end

  def show
    @team = CrmTeam.includes(:crm_members).find(params[:id])
    @groups = load_groups
  end

  def new
    @team = CrmTeam.new
    @groups = load_groups
  end

  def create
    @team = CrmTeam.new(team_params)

    if @team.save
      redirect_to teams_path, notice: "Team created successfully."
    else
      @groups = load_groups
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @team = CrmTeam.find(params[:id])
    @groups = load_groups
  end

  def update
    @team = CrmTeam.find(params[:id])

    # Track if doorflow_group_id is changing
    old_group_id = @team.doorflow_group_id
    new_group_id = team_params[:doorflow_group_id]
    group_mapping_changing = new_group_id.present? && old_group_id.to_s != new_group_id.to_s

    if @team.update(team_params)
      enqueue_team_sync_if_group_changed(@team) if group_mapping_changing
      redirect_to teams_path, notice: build_update_notice(group_mapping_changing)
    else
      @groups = load_groups
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team = CrmTeam.find(params[:id])
    @team.destroy
    redirect_to teams_path, notice: "Team deleted successfully."
  end

  private

  def team_params
    params.require(:crm_team).permit(:name, :description, :doorflow_group_id)
  end

  def doorflow_service
    @doorflow_service ||= DoorflowPersonService.new(client: doorflow)
  end

  def load_groups
    return [] unless doorflow_connected?

    doorflow_service.fetch_groups
  rescue DoorflowPersonService::Error => e
    flash.now[:alert] = "Could not load DoorFlow groups: #{e.message}"
    []
  end

  def enqueue_team_sync_if_group_changed(team)
    return unless doorflow_connected?

    SyncTeamMembersJob.perform_later(team.id)
  end

  def build_update_notice(group_changed)
    base = "Team updated successfully."
    return base unless group_changed && doorflow_connected?

    "#{base} Member sync queued."
  end
end
