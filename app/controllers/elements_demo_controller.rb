# frozen_string_literal: true

# Demonstrates the DoorFlow.js host SDK embedded in a web frontend — the
# integration path documented in
# `doorguard/docs/doorflow-elements-js-integration-guide.html`.
#
# Visit `/elements-demo` (optionally `?member_id=<crm_member_id>`) and the
# page mounts the member widget via `DoorFlow.mount('#df-member', { ... })`.
# Pick whichever CrmMember is the most useful demo subject; in production
# the integrator would mint a session for `current_user` and embed it on
# their own member-portal page.
class ElementsDemoController < ApplicationController
  include DoorflowClient
  include MemberSession

  def show
    @member = pick_member
    return if @member.nil?

    @member_result = mint("member")
    @admin_result  = mint("admin")
  end

  private

  def mint(widget_type)
    ElementsSessionMinter.new(
      member:             @member,
      doorflow_connected: doorflow_connected?,
      doorflow_client:    doorflow,
      widget_type:        widget_type
    ).call
  end

  # Demo-only convenience: prefer ?member_id=, then the cookie-logged-in
  # member, then the first synced member with a doorflow_person_id, then
  # any member at all (so the page can still render the "not synced" copy).
  def pick_member
    if params[:member_id].present?
      CrmMember.find_by(id: params[:member_id])
    else
      current_member ||
        CrmMember.where.not(doorflow_person_id: nil).first ||
        CrmMember.first
    end
  end
end
