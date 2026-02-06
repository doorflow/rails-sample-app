import { Controller } from "@hotwired/stimulus"

// Handles team selection checkbox UI updates
export default class extends Controller {
  static targets = ["card"]

  toggle(event) {
    const checkbox = event.target
    const card = checkbox.closest("label")

    if (checkbox.checked) {
      card.classList.remove("border-gray-200", "bg-white", "hover:border-gray-300")
      card.classList.add("border-orange-400", "bg-orange-50", "hover:border-orange-500")
      this.updateCheckmark(card, true)
      this.updateTextColor(card, true)
    } else {
      card.classList.remove("border-orange-400", "bg-orange-50", "hover:border-orange-500")
      card.classList.add("border-gray-200", "bg-white", "hover:border-gray-300")
      this.updateCheckmark(card, false)
      this.updateTextColor(card, false)
    }
  }

  updateCheckmark(card, checked) {
    const checkContainer = card.querySelector("[class*='rounded-full']")
    if (!checkContainer) return

    if (checked) {
      checkContainer.classList.remove("border-gray-300", "bg-white")
      checkContainer.classList.add("border-orange-500", "bg-orange-500")
      checkContainer.innerHTML = `
        <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
        </svg>
      `
    } else {
      checkContainer.classList.remove("border-orange-500", "bg-orange-500")
      checkContainer.classList.add("border-gray-300", "bg-white")
      checkContainer.innerHTML = ""
    }
  }

  updateTextColor(card, checked) {
    const teamName = card.querySelector("p.font-semibold")
    if (!teamName) return

    if (checked) {
      teamName.classList.remove("text-gray-700")
      teamName.classList.add("text-orange-700")
    } else {
      teamName.classList.remove("text-orange-700")
      teamName.classList.add("text-gray-700")
    }
  }
}
