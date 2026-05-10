import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saveBtn"]
  static values = {
    transactionId: String
  }

  // The form is foster-parented by the HTML5 parser to before the <table>,
  // outside this controller's element (<tr>). Stimulus targets are scoped to
  // this.element, so we look the form up by its known ID instead.
  get form() {
    return document.getElementById(`transaction_${this.transactionIdValue}_edit_form`)
  }

  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
    this.saveBtnTarget.addEventListener("click", this.handleSave.bind(this))
    this.element.addEventListener("blur", this.blur.bind(this), true)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
    this.saveBtnTarget.removeEventListener("click", this.handleSave.bind(this))
    this.element.removeEventListener("blur", this.blur.bind(this), true)
  }

  focusNext(e) {
    const inputs = this.element.querySelectorAll(".form-input")
    const idx = Array.from(inputs).indexOf(e.target)
    if (idx >= 0 && idx < inputs.length - 1) {
      inputs[idx + 1].focus()
    }
  }

  blur(e) {
    if (e.target.dataset.preventBlur === "true") return
    // Defer so document.activeElement reflects the new focus target
    setTimeout(() => {
      const focused = document.activeElement
      if (!this.element.contains(focused)) {
        this.handleSave(e)
      }
    }, 0)
  }

  handleKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.form.requestSubmit()
    } else if (e.key === "Escape") {
      e.preventDefault()
      this.cancel(e)
    }
  }

  handleSave(e) {
    e.preventDefault()
    if (this.form.reportValidity()) {
      this.form.requestSubmit()
    }
  }

  cancel(e) {
    e.preventDefault()
    // Remove the foster-parented form (inserted before the <table> by row_edit_controller)
    const form = this.form
    if (form) form.remove()
    this.element.remove()
    const originalRow = document.querySelector(`tr[data-txn-id="${this.transactionIdValue}"]`)
    if (originalRow) {
      originalRow.style.display = ""
    }
  }
}
