import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.boundHandleClick = this.handleClick.bind(this)
    this.element.addEventListener("click", this.boundHandleClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundHandleClick)
  }

  handleClick(e) {
    if (e.target.closest(".form-input") || e.target.closest(".autocomplete-results")) {
      return
    }
    if (e.target.closest(".transaction-row--editing")) {
      return
    }
    const row = e.target.closest("tr")
    if (!row) return
    const txnId = row.dataset.txnId
    if (!txnId) return
    e.preventDefault()
    e.stopPropagation()
    this.loadEditRow(txnId)
  }

  loadEditRow(txnId) {
    const row = this.element.querySelector(`tr[data-txn-id="${txnId}"]`)
    if (!row) return
    const accountId = row.dataset.accountId
    const tbody = row.parentElement
    const table = tbody.closest("table")

    fetch(`/transactions/${txnId}/edit?account_id=${accountId}`, {
      headers: { "Accept": "text/html" }
    })
      .then(r => r.text())
      .then(html => {
        const range = document.createRange()
        range.selectNodeContents(tbody)
        const fragment = range.createContextualFragment(html)
        const newRow = fragment.querySelector("tr.transaction-row--editing")
        if (newRow) {
          // The HTML5 parser foster-parents <form> elements out of
          // <tr>/<td> into siblings before the <table>. Pull those
          // forms out of the fragment and insert them before the
          // table so they are in the live DOM and findable by ID.
          const forms = fragment.querySelectorAll("form")
          if (table && forms.length) {
            forms.forEach(form => table.before(form))
          }

          row.insertAdjacentElement("afterend", newRow)
          row.style.display = "none"
        }
      })
  }
}
