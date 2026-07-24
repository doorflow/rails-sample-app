# frozen_string_literal: true

# Load the DoorFlow SDK wrapper which provides the Stripe-style interface
require "doorflow"

# Point the SDK at a custom DoorFlow instance when DOORFLOW_API_BASE is set.
# DoorflowClientBuilder also passes base_path to the auth object, but the
# Client itself reads from DoorFlow::Configuration.default — so setting it
# globally here ensures both auth and resource calls hit the same host.
if ENV["DOORFLOW_API_BASE"].present?
  DoorFlow.api_base = ENV["DOORFLOW_API_BASE"]
end
