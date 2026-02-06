# frozen_string_literal: true

# Educational callout component that explains SDK usage and architecture.
# Appears throughout the example to teach developers about integration patterns.
# Matches the TypeScript DevNote.tsx component styling.
class DevNoteComponent < ViewComponent::Base
  VARIANTS = {
    info: {
      colors: {
        bg: "bg-gradient-to-br from-indigo-100 to-indigo-200",
        border: "border-indigo-300",
        icon_bg: "bg-indigo-100",
        icon_color: "text-indigo-700",
        title: "text-indigo-800",
        content: "text-indigo-700",
        code: "bg-black/10 text-purple-600",
        muted: "text-gray-600"
      },
      icon: "info"
    },
    tip: {
      colors: {
        bg: "bg-gradient-to-br from-emerald-100 to-emerald-200",
        border: "border-emerald-300",
        icon_bg: "bg-emerald-100",
        icon_color: "text-emerald-700",
        title: "text-gray-900",
        content: "text-gray-900",
        code: "bg-black/10 text-purple-600",
        muted: "text-gray-600"
      },
      icon: "lightbulb"
    },
    warning: {
      colors: {
        bg: "bg-gradient-to-br from-amber-100 to-amber-200",
        border: "border-amber-300",
        icon_bg: "bg-amber-100",
        icon_color: "text-amber-700",
        title: "text-amber-800",
        content: "text-amber-700",
        code: "bg-black/10 text-purple-600",
        muted: "text-gray-600"
      },
      icon: "alert-triangle"
    },
    code: {
      colors: {
        bg: "bg-gradient-to-br from-green-50 to-green-100",
        border: "border-emerald-300",
        icon_bg: "bg-emerald-100",
        icon_color: "text-emerald-700",
        title: "text-emerald-800",
        content: "text-emerald-900",
        code: "bg-black/10 text-purple-600",
        muted: "text-gray-600"
      },
      icon: "code"
    }
  }.freeze

  def initialize(variant: :info, title: nil, sdk_method: nil, file_path: nil)
    @variant = variant.to_sym
    @title = title
    @sdk_method = sdk_method
    @file_path = file_path
  end

  def variant_config
    VARIANTS[@variant] || VARIANTS[:info]
  end

  def colors
    variant_config[:colors]
  end

  def icon_name
    variant_config[:icon]
  end

  def container_classes
    "#{colors[:bg]} border #{colors[:border]} rounded-xl overflow-hidden"
  end

  def header_classes
    "flex items-center gap-3 px-4 py-2 border-b #{colors[:border]}"
  end

  def icon_container_classes
    "#{colors[:icon_bg]} rounded-lg p-1.5 flex items-center justify-center"
  end

  def icon_classes
    "w-4 h-4 #{colors[:icon_color]}"
  end

  def title_classes
    "text-xs font-bold uppercase tracking-wider #{colors[:title]}"
  end

  def formatted_title
    return nil unless @title
    "Devs: #{@title}"
  end

  def content_classes
    "text-sm #{colors[:content]} leading-relaxed [&_code]:bg-black/10 [&_code]:text-purple-600 [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:rounded [&_code]:text-xs [&_code]:font-mono [&_a]:text-indigo-600 [&_a]:underline"
  end

  def code_classes
    "font-mono text-sm font-semibold #{colors[:code]} px-3 py-2 rounded-lg"
  end

  def file_path_classes
    "text-xs #{colors[:muted]} bg-black/10 px-2 py-0.5 rounded font-mono"
  end

  attr_reader :title, :sdk_method, :file_path
end
