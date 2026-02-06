# frozen_string_literal: true

module ApplicationHelper
  # Check if DoorFlow is connected
  def doorflow_connected?
    client = DoorflowClient.new
    client.connected?
  rescue StandardError
    false
  end

  # Renders a Lucide icon using the lucide-rails gem
  def render_icon(name, css_class: "w-4 h-4")
    lucide_icon(name, class: css_class)
  end

  # Renders a feature card for the home page using DaisyUI
  # Matches TypeScript/Chakra UI design: vertical layout with icon on top
  def render_feature_card(icon:, title:, description:, sdk_methods:, color:)
    color_classes = {
      "purple" => { bg: "bg-purple-50", text: "text-purple-600", badge_bg: "bg-purple-50", badge_text: "text-purple-700" },
      "blue" => { bg: "bg-blue-50", text: "text-blue-600", badge_bg: "bg-blue-50", badge_text: "text-blue-700" },
      "green" => { bg: "bg-green-50", text: "text-green-600", badge_bg: "bg-green-50", badge_text: "text-green-700" },
      "orange" => { bg: "bg-orange-50", text: "text-orange-600", badge_bg: "bg-orange-50", badge_text: "text-orange-700" },
      "pink" => { bg: "bg-pink-50", text: "text-pink-600", badge_bg: "bg-pink-50", badge_text: "text-pink-700" }
    }

    c = color_classes[color]

    content_tag(:div, class: "card bg-base-100 shadow-sm border border-base-300 hover:shadow-lg hover:-translate-y-1 transition-all duration-300") do
      content_tag(:div, class: "card-body") do
        # Icon box - at top
        icon_html = content_tag(:div, class: "#{c[:bg]} #{c[:text]} rounded-xl p-3 w-fit mb-4") do
          render_icon(icon, css_class: "w-7 h-7")
        end

        # Title
        title_html = content_tag(:h2, title, class: "card-title text-base")

        # Description
        desc_html = content_tag(:p, description, class: "text-sm text-base-content/70")

        # SDK method badges - filled style to match Chakra
        badges_html = content_tag(:div, class: "card-actions mt-4 flex-wrap") do
          safe_join(sdk_methods.map do |method|
            content_tag(:span, method, class: "px-3 py-1 #{c[:badge_bg]} #{c[:badge_text]} rounded-full text-xs font-semibold font-mono")
          end)
        end

        icon_html + title_html + desc_html + badges_html
      end
    end
  end
end
