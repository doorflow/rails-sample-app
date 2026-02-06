# frozen_string_literal: true

# Sticky navigation header for the application.
# Displays the logo and nav items with CoWork HQ branding.
class NavigationComponent < ViewComponent::Base
  NAV_ITEMS = [
    { name: "Home", path: :root_path, icon: "home" },
    { name: "Members", path: :members_path, icon: "users" },
    { name: "Teams", path: :teams_path, icon: "user-group" },
    { name: "Settings", path: :settings_path, icon: "cog" }
  ].freeze

  def initialize(current_path: nil)
    @current_path = current_path
  end

  def nav_items
    NAV_ITEMS.map do |item|
      path = helpers.send(item[:path])
      active = @current_path == path
      item.merge(path: path, active: active)
    end
  end

  def nav_item_classes(active:)
    base = "btn btn-sm rounded-full transition-all duration-200"
    if active
      "#{base} btn-ghost bg-white text-primary shadow-md"
    else
      "#{base} btn-ghost text-white bg-white/20 hover:bg-white/30"
    end
  end
end
