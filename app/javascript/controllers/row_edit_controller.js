import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.element.addEventListener("click", this.handleClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleClick.bind(this))
  }

  handleClick(e) {
    if (e.target.closest(".form-input") || e.target.closest(".autocomplete-results")) {
      return
    }
    if (e.target.closest(".transaction-row--editing")) {
      return
    }
    const row = e.currentTarget.closest("tr")
    if (!row) return
    const txnId = row.dataset.txnId
    if (!txnId) return
    e.preventDefault()
    e.stopPropagation()
    this.loadEditRow(txnId)
  }

  loadEditRow(txnId) {
    const row = this.element.querySelector(`tr[data-txn-id="${txnId}"]`)
    const line = row.querySelector("td.col-date")
    const accountPath = window.location.pathname
    const accountId = line.dataset.accountId
    
    fetch(`/transactions/${txnId}/edit?account_id=${accountId}`, {
      headers: { "Turbo-Frame": "transaction_" + txnId + "_edit" }
    })
      .then(r => r.text())
      .then(html => {
        const template = document.createElement("template")
        template.innerHTML = html
        const frame = template.content.firstChild
        if (frame && frame.id === "transaction_" + txnId + "_edit") {
          if (row) {
            row.insertAdjacentElement("afterend", frame)
            row.style.display = "none"
          }
        }
      })
  }
}
