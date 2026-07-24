# frozen_string_literal: true

# Provides DoorFlow SDK client access to controllers
#
# @example Using in a controller
#   class MembersController < ApplicationController
#     include DoorflowClient
#
#     def index
#       @people = doorflow.people.list.data if doorflow_connected?
#     end
#   end
module DoorflowClient
  extend ActiveSupport::Concern

  included do
    helper_method :doorflow_connected?, :doorflow_configured?
  end

  private

  # Get a DoorFlow client instance
  # @return [DoorFlow::Client, nil] the configured client
  def doorflow
    @doorflow ||= DoorflowClientBuilder.build
  end

  # Get the auth object for DoorFlow
  # @return [DoorFlow::Auth::DoorFlowAuth, nil] the auth object
  def doorflow_auth
    @doorflow_auth ||= DoorflowClientBuilder.build_auth
  end

  # Check if DoorFlow OAuth is connected (has valid tokens)
  # @return [Boolean] true if connected
  def doorflow_connected?
    DoorflowClientBuilder.connected?
  end

  # Check if all required environment variables are set
  # @return [Boolean] true if configured
  def doorflow_configured?
    DoorflowClientBuilder.configured?
  end

  # Get list of missing environment variables
  # @return [Array<String>] missing variable names
  def missing_doorflow_config
    DoorflowClientBuilder::REQUIRED_ENV.select { |key| ENV[key].blank? }
  end

  # Get connection status for display
  # @return [Hash] status information
  def doorflow_status
    return { state: :not_configured, missing_config: missing_doorflow_config } unless doorflow_configured?
    return { state: :not_connected } unless doorflow_connected?

    tokens = TokenStorageService.new.load
    account_info = fetch_account_info

    {
      state: :connected,
      expires_at: tokens&.expires_at,
      scope: tokens&.scope,
      account_name: account_info[:account_name],
      user_email: account_info[:user_email]
    }
  end

  # Fetch account information from DoorFlow
  # @return [Hash] account name and user email
  def fetch_account_info
    account = doorflow.account.retrieve
    {
      account_name: account.respond_to?(:name) ? account.name : account[:name],
      user_email:   extract_user_email(account.respond_to?(:user) ? account.user : account[:user])
    }
  rescue StandardError => e
    # Avoid #message because some SDK error responses include large inspect
    # graphs that overflow the stack on interpolation. Class name is enough.
    Rails.logger.warn "[DoorflowClient] Failed to fetch account info: #{e.class}"
    { account_name: nil, user_email: nil }
  end

  # The SDK sometimes returns the user as a struct-like object and sometimes
  # as a plain Hash (depending on which deserialiser path runs). Normalise.
  def extract_user_email(user)
    return nil if user.nil?
    return user.email if user.respond_to?(:email)
    user[:email] || user["email"]
  end

  # Generate OAuth authorization URL
  # @return [Array] [url, state, code_verifier]
  def doorflow_authorization_url
    raise "DoorFlow not configured" unless doorflow_configured?

    doorflow_auth.authorization_url(
      scopes: ENV.fetch("DOORFLOW_SCOPES", "read write").split,
      use_pkce: true
    )
  end

  # Handle OAuth callback
  def handle_doorflow_callback(code:, state:, expected_state: nil, code_verifier: nil)
    raise "DoorFlow not configured" unless doorflow_configured?

    doorflow_auth.handle_callback(
      code: code,
      state: state,
      expected_state: expected_state,
      code_verifier: code_verifier
    )
  end

  # Disconnect from DoorFlow
  def doorflow_disconnect
    doorflow_auth&.disconnect
  end

  # Force token refresh
  def doorflow_refresh_token
    doorflow_auth.refresh_access_token
  end
end
