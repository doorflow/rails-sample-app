# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    def status
      status = doorflow_status

      render json: {
        configured: status[:state] != :not_configured,
        missing_config: status[:missing_config] || [],
        connected: status[:state] == :connected,
        expires_at: status[:expires_at],
        scope: status[:scope]
      }
    end

    def connect
      auth_url, state, code_verifier = doorflow_authorization_url

      session[:oauth_state] = state
      session[:oauth_code_verifier] = code_verifier
      redirect_to auth_url, allow_other_host: true
    end

    def callback
      unless params[:code].present?
        redirect_to root_path, alert: "Authorization failed: no code received"
        return
      end

      expected_state = session.delete(:oauth_state)
      code_verifier = session.delete(:oauth_code_verifier)
      handle_doorflow_callback(
        code: params[:code],
        state: params[:state],
        expected_state: expected_state,
        code_verifier: code_verifier
      )

      redirect_to root_path, notice: "Successfully connected to DoorFlow!"
    rescue StandardError => e
      error_details = []
      error_details << "class=#{e.class.name}"
      error_details << "status=#{e.status}" if e.respond_to?(:status) && e.status
      error_details << "code=#{e.code}" if e.respond_to?(:code) && e.code
      error_details << "raw_response=#{e.raw_response}" if e.respond_to?(:raw_response) && e.raw_response
      Rails.logger.error "OAuth callback failed: #{error_details.join(', ')}"
      redirect_to root_path, alert: "Authorization failed: #{e.respond_to?(:code) ? e.code : e.class.name}"
    end

    def disconnect
      doorflow_disconnect

      redirect_to root_path, notice: "Disconnected from DoorFlow"
    rescue StandardError => e
      Rails.logger.error "Disconnect failed: #{e.message}"
      redirect_to root_path, alert: "Failed to disconnect: #{e.message}"
    end

    def refresh
      doorflow_refresh_token

      redirect_to root_path, notice: "Token refreshed successfully"
    rescue StandardError => e
      Rails.logger.error "Token refresh failed: #{e.message}"
      redirect_to root_path, alert: "Failed to refresh token: #{e.message}"
    end
  end
end
