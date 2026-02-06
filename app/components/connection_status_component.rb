# frozen_string_literal: true

# Displays the current DoorFlow OAuth connection status.
# Shows different states and provides actions for connecting/disconnecting.
class ConnectionStatusComponent < ViewComponent::Base
  STATES = %i[loading not_configured connected not_connected].freeze

  def initialize(state:, expires_at: nil, scope: nil, missing_config: [], account_name: nil, user_email: nil)
    @state = state.to_sym
    @expires_at = expires_at
    @scope = scope
    @missing_config = missing_config
    @account_name = account_name
    @user_email = user_email
  end

  attr_reader :account_name, :user_email

  def loading?
    @state == :loading
  end

  def not_configured?
    @state == :not_configured
  end

  def connected?
    @state == :connected
  end

  def not_connected?
    @state == :not_connected
  end

  def container_classes
    case @state
    when :connected
      "card bg-base-100 shadow-md border border-success/30"
    when :not_connected
      "card bg-[linear-gradient(135deg,#667eea_0%,#764ba2_100%)] shadow-xl text-white"
    when :not_configured
      "card bg-base-100 shadow-md border border-warning/30"
    else
      "card bg-base-100 shadow-md"
    end
  end

  def expires_in_words
    return nil unless @expires_at

    time = Time.at(@expires_at)
    helpers.time_ago_in_words(time)
  end

  def scopes_list
    @scope&.split(" ") || []
  end

  attr_reader :missing_config
end
