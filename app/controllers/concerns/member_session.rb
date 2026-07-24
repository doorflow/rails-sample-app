# frozen_string_literal: true

# Cookie-based "current CrmMember" helpers. Sample-app only — pretends to
# be the host product's own auth so a native client (e.g. the Swift sample)
# can sign in as a member without setting up a real auth stack.
module MemberSession
  extend ActiveSupport::Concern

  COOKIE_NAME = :doorflow_sample_member

  def current_member
    @current_member ||= CrmMember.find_by(id: cookies.signed[COOKIE_NAME])
  end

  def member_signed_in?
    current_member.present?
  end

  def sign_in_member(member)
    cookies.signed[COOKIE_NAME] = {
      value:     member.id,
      httponly:  true,
      same_site: :lax,
      expires:   8.hours.from_now
    }
    @current_member = member
  end

  def sign_out_member
    cookies.delete(COOKIE_NAME)
    @current_member = nil
  end

  def require_member!
    return if member_signed_in?

    render json: { error: "not_logged_in" }, status: :unauthorized
  end
end
