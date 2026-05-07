import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "saveBtn"]
  static values = {
    transactionId: String
  }

  connect() {
    this.formTarget.addEventListener("keydown", this.handleKeydown.bind(this))
    this.saveBtnTarget.addEventListener("click", this.handleSave.bind(this))
  }

  disconnect() {
    this.formTarget.removeEventListener("keydown", this.handleKeydown.bind(this))
    this.saveBtnTarget.removeEventListener("click", this.handleSave.bind(this))
  }

  focusNext(e) {
    const inputs = this.formTarget.querySelectorAll(".form-input")
    const idx = Array.from(inputs).indexOf(e.target)
    if (idx >= 0 && idx < inputs.length - 1) {
      inputs[idx + 1].focus()
    }
  }

  blur(e) {
    if (e.target.dataset.preventBlur === "true") return
    const inputs = this.formTarget.querySelectorAll(".form-input")
    const focused = document.activeElement
    if (!inputs.includes(focused)) {
      this.handleSave(e)
    }
  }

  handleKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.formTarget.requestSubmit()
    } else if (e.key === "Escape") {
      e.preventDefault()
      this.cancel(e)
    }
  }

  handleSave(e) {
    e.preventDefault()
    if (this.formTarget.reportValidity()) {
      this.formTarget.submit()
    }
  }

  cancel(e) {
    e.preventDefault()
    this.element.remove()
    const originalRow = document.querySelector(`tr[data-txn-id="${this.transactionIdValue}"]`)
    if (originalRow) {
      originalRow.style.display = ""
    }
  }
}
