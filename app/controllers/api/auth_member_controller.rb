# frozen_string_literal: true

module Api
  # Mock CRM-member login for native clients (e.g. the Swift sample). No
  # password — pretends the host product has its own auth and the client
  # has already passed it.
  class AuthMemberController < ApplicationController
    include MemberSession

    skip_before_action :verify_authenticity_token

    def login
      email  = params.dig(:email)&.to_s&.strip&.downcase
      return render(json: { error: "email_required" }, status: :bad_request) if email.blank?

      member = CrmMember.find_by("LOWER(email) = ?", email)
      return render(json: { error: "member_not_found" }, status: :not_found) if member.nil?

      sign_in_member(member)
      render json: serialize(member)
    end

    def me
      return render(json: { error: "not_logged_in" }, status: :unauthorized) if current_member.nil?

      render json: serialize(current_member)
    end

    def logout
      sign_out_member
      render json: { ok: true }
    end

    private

    def serialize(m)
      {
        id:                  m.id,
        email:               m.email,
        first_name:          m.first_name,
        last_name:           m.last_name,
        doorflow_person_id:  m.doorflow_person_id
      }
    end
  end
end
