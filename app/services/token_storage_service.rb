# frozen_string_literal: true

# Token storage service that persists OAuth tokens to a JSON file.
# Uses the SDK's TokenStorage interface.
class TokenStorageService < DoorFlow::Auth::TokenStorage
  TOKEN_FILE = Rails.root.join("tmp", "doorflow_tokens.json")

  def load
    return nil unless File.exist?(TOKEN_FILE)

    data = JSON.parse(File.read(TOKEN_FILE), symbolize_names: true)
    StoredTokens.new(
      access_token: data[:access_token],
      refresh_token: data[:refresh_token],
      expires_at: data[:expires_at],
      scope: data[:scope]
    )
  rescue JSON::ParserError, Errno::ENOENT => e
    Rails.logger.warn "Failed to load tokens: #{e.message}"
    nil
  end

  def save(tokens)
    data = {
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_at: tokens.expires_at,
      scope: tokens.scope
    }

    FileUtils.mkdir_p(File.dirname(TOKEN_FILE))
    File.write(TOKEN_FILE, JSON.pretty_generate(data))
  rescue StandardError => e
    Rails.logger.error "Failed to save tokens: #{e.message}"
    raise
  end

  def clear
    File.delete(TOKEN_FILE) if File.exist?(TOKEN_FILE)
  rescue StandardError => e
    Rails.logger.error "Failed to clear tokens: #{e.message}"
  end
end
