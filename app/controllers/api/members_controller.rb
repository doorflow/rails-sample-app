# frozen_string_literal: true

module Api
  class MembersController < ApplicationController
    def sync
      unless doorflow_connected?
        if request.format.json?
          return render json: { error: "Not connected to DoorFlow" }, status: :unauthorized
        else
          return redirect_to settings_path, alert: "Not connected to DoorFlow"
        end
      end

      dry_run = params[:dry_run] == "true"
      member_ids = params[:member_ids]

      members = if member_ids.present?
                  CrmMember.where(id: member_ids)
                else
                  CrmMember.all
                end

      service = MemberSyncService.new(client: doorflow)
      results = service.sync(members, dry_run: dry_run)

      session[:sync_results] = results

      if request.format.json?
        render json: results
      else
        redirect_to settings_path, notice: "Sync completed"
      end
    rescue StandardError => e
      Rails.logger.error "Sync failed: #{e.message}"

      if request.format.json?
        render json: { error: e.message }, status: :unprocessable_entity
      else
        redirect_to settings_path, alert: "Sync failed: #{e.message}"
      end
    end

    def link
      member = CrmMember.find(params[:id])
      doorflow_person_id = params[:doorflow_person_id]

      member.update!(doorflow_person_id: doorflow_person_id)

      render json: { success: true, doorflow_person_id: doorflow_person_id }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def unlink
      member = CrmMember.find(params[:id])
      member.update!(doorflow_person_id: nil)

      render json: { success: true }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
