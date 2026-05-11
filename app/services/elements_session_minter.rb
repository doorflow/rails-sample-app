# frozen_string_literal: true

# Mints a DoorFlow Elements session JWT for a given CrmMember by calling
# the SDK's `client.admin_sessions.create(...)` or
# `client.member_sessions.create(...)`. Used by both the JSON API
# (Swift app) and the web demo page (browser-embedded widget) so they
# stay in lockstep.
#
# Returns a Result struct: success?/token/error/status/detail.
class ElementsSessionMinter
  Result = Struct.new(:success?, :token, :expires_in, :error, :status, :detail, keyword_init: true)

  WIDGET_TYPES = %w[member admin].freeze

  def initialize(member:, doorflow_connected:, doorflow_client:, widget_type: "member")
    @member             = member
    @doorflow_connected = doorflow_connected
    @doorflow_client    = doorflow_client
    @widget_type        = WIDGET_TYPES.include?(widget_type) ? widget_type : "member"
  end

  def call
    return failure(:not_logged_in,          :unauthorized)        if @member.nil?
    return failure(:doorflow_not_connected, :service_unavailable) unless @doorflow_connected
    return failure(:no_access_token,        :service_unavailable) if @doorflow_client.nil?

    session = sessions_proxy.create(member: member_payload)
    Result.new(success?: true, token: session.token, expires_in: session.expires_in)
  rescue DoorFlow::ApiError => e
    failure(:doorflow_session_mint_failed, :bad_gateway, e.message)
  end

  private

  def sessions_proxy
    @widget_type == "admin" ? @doorflow_client.admin_sessions : @doorflow_client.member_sessions
  end

  def member_payload
    {
      external_id: @member.id.to_s,
      name:        "#{@member.first_name} #{@member.last_name}",
      email:       @member.email
    }
  end

  def failure(error, status, detail = nil)
    Result.new(success?: false, error: error, status: status, detail: detail)
  end
end
