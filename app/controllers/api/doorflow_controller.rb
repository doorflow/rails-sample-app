# frozen_string_literal: true

module Api
  class DoorflowController < ApplicationController
    before_action :ensure_connected

    def people
      people = doorflow.people.list(params.permit(:page, :per_page, :search).to_h.symbolize_keys)

      render json: people.data.map(&:attributes)
    end

    def person
      person = doorflow.people.retrieve(params[:id])

      render json: person.attributes
    end

    def groups
      groups = doorflow.groups.list

      render json: groups.data.map(&:attributes)
    end

    def credentials
      credentials = doorflow.credentials.list(params.permit(:person_id).to_h.symbolize_keys)

      render json: credentials.data.map(&:attributes)
    end

    def create_credential
      person_id = params[:person_id]

      # Build the credential value based on form inputs
      value = if params[:pin_mode] == "auto"
                "******"  # Auto-generate PIN
              elsif params[:pin_value].present?
                params[:pin_value]
              else
                params[:value]
              end

      credential = doorflow.credentials.create(
        person_id: person_id,
        credential_type_id: params[:credential_type_id],
        value: value || ""
      )

      render json: credential.attributes, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_credential
      doorflow.credentials.delete(params[:id], person_id: params[:person_id])

      render json: { success: true }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_person_groups
      person_id = params[:person_id]
      group_ids = params[:group_ids] || []

      person = doorflow.people.retrieve(person_id)
      person.update(group_ids: group_ids)

      render json: { success: true, group_ids: group_ids }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def ensure_connected
      return if doorflow_connected?

      render json: { error: "Not connected to DoorFlow" }, status: :unauthorized
    end

    def credential_params
      params.permit(:person_id, :credential_type_id, :value, :pin_value, :pin_mode)
    end
  end
end
