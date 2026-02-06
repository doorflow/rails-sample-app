import { Controller } from "@hotwired/stimulus"

// Handles dynamic credential form behavior based on credential type category
// Categories are determined by label/slug:
// - PIN types: show auto-generate vs manual PIN options
// - Mobile types: show invitation message (no value needed)
// - Card types (default): show card number input
export default class extends Controller {
  static targets = ["typeOption", "cardInput", "pinInput", "mobileInput", "pinAutoMessage", "pinManualInput", "submitButton"]

  connect() {
    this.selectedType = null
    this.selectedCategory = null
    this.isAutoGenerate = true
  }

  selectType(event) {
    const radio = event.target
    const option = radio.closest('[data-credential-form-target="typeOption"]')
    const category = option.dataset.category
    const typeId = option.dataset.typeId

    this.selectedType = typeId
    this.selectedCategory = category

    // Hide all input sections first
    this.hideAllInputs()

    // Show the appropriate input based on category
    if (category === 'card') {
      this.showTarget('cardInput')
    } else if (category === 'pin') {
      this.showTarget('pinInput')
      this.isAutoGenerate = true
      this.updatePinMode()
    } else if (category === 'mobile') {
      this.showTarget('mobileInput')
    }
  }

  togglePinMode(event) {
    const mode = event.target.value
    this.isAutoGenerate = (mode === 'auto')
    this.updatePinMode()
  }

  updatePinMode() {
    if (this.hasPinAutoMessageTarget && this.hasPinManualInputTarget) {
      if (this.isAutoGenerate) {
        this.pinAutoMessageTarget.classList.remove('hidden')
        this.pinManualInputTarget.classList.add('hidden')
      } else {
        this.pinAutoMessageTarget.classList.add('hidden')
        this.pinManualInputTarget.classList.remove('hidden')
      }
    }
  }

  hideAllInputs() {
    if (this.hasCardInputTarget) this.cardInputTarget.classList.add('hidden')
    if (this.hasPinInputTarget) this.pinInputTarget.classList.add('hidden')
    if (this.hasMobileInputTarget) this.mobileInputTarget.classList.add('hidden')
  }

  showTarget(name) {
    const target = this[`${name}Target`]
    if (target) {
      target.classList.remove('hidden')
    }
  }
}
