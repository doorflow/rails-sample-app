# frozen_string_literal: true

module Api
  # Mint a DoorFlow Elements session JWT for the currently logged-in
  # CrmMember via the DoorFlow SDK's member/admin session proxies.
  class ElementsController < ApplicationController
    include MemberSession
    include DoorflowClient

    skip_before_action :verify_authenticity_token

    def session
      result = ElementsSessionMinter.new(
        member:             current_member,
        doorflow_connected: doorflow_connected?,
        doorflow_client:    doorflow
      ).call

      unless result.success?
        return render(json: { error: result.error.to_s, detail: result.detail }, status: result.status)
      end

      # The widget URL is intentionally not returned. Constructing it is the
      # client SDK's job — it knows its environment, platform context, and
      # the widget path/query convention. Keeping URL construction out of
      # host backends means doorguard can change those details without
      # breaking every customer integration.
      render json: { token: result.token, expires_in: result.expires_in }
    end
  end
end
