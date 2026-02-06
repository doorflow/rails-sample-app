# frozen_string_literal: true

# Builds a configured DoorFlow client for use anywhere in the app.
# Centralizes all DoorFlow SDK configuration in one place.
class DoorflowClientBuilder
  REQUIRED_ENV = %w[DOORFLOW_CLIENT_ID DOORFLOW_CLIENT_SECRET DOORFLOW_REDIRECT_URI].freeze

  class << self
    # Build a DoorFlow client
    # @return [DoorFlow::Client, nil] client or nil if not connected
    def build
      return nil unless configured?

      auth = build_auth
      return nil unless auth.authenticated?

      DoorFlow::Client.new(auth: auth)
    end

    # Build the auth object
    # @return [DoorFlow::Auth::DoorFlowAuth, nil]
    def build_auth
      return nil unless configured?

      DoorFlow::Auth::DoorFlowAuth.new(
        client_id: ENV.fetch("DOORFLOW_CLIENT_ID"),
        client_secret: ENV.fetch("DOORFLOW_CLIENT_SECRET"),
        redirect_uri: ENV.fetch("DOORFLOW_REDIRECT_URI"),
        storage: TokenStorageService.new,
        base_path: ENV.fetch("DOORFLOW_API_BASE", "https://api.doorflow.com")
      )
    end

    # Check if DoorFlow is configured
    # @return [Boolean]
    def configured?
      REQUIRED_ENV.all? { |key| ENV[key].present? }
    end

    # Check if DoorFlow is connected (configured + authenticated)
    # @return [Boolean]
    def connected?
      configured? && build_auth&.authenticated?
    end

    # Alias for backward compatibility
    alias_method :auth, :build_auth
  end
end
