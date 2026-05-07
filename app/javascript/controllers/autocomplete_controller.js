import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["results"]
  static values = {
    url: String,
    field: String
  }

  connect() {
    this.element.addEventListener("input", this.handleInput.bind(this))
    this.element.addEventListener("focus", this.handleFocus.bind(this))
    this.resultsTarget.addEventListener("click", this.handleResultClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("input", this.handleInput.bind(this))
    this.element.removeEventListener("focus", this.handleFocus.bind(this))
    this.resultsTarget.removeEventListener("click", this.handleResultClick.bind(this))
  }

  get inputTarget() {
    return this.element.querySelector("select, input")
  }

  handleInput(e) {
    const query = e.target.value
    if (query.length < 2) {
      this.resultsTarget.innerHTML = ""
      return
    }
    fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
      .then(r => r.json())
      .then(data => this.renderResults(data, query))
  }

  handleFocus(e) {
    if (this.resultsTarget.innerHTML === "") {
      this.handleInput(e)
    }
  }

  handleResultClick(e) {
    const item = e.target.closest("[data-autocomplete-value]")
    if (!item) return
    e.preventDefault()
    e.stopPropagation()
    const value = item.dataset.autocompleteValue
    const label = item.dataset.autocompleteLabel
    this.inputTarget.value = label
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.resultsTarget.innerHTML = ""
    this.inputTarget.focus()
  }

  renderResults(items, query) {
    if (items.length === 0) {
      this.resultsTarget.innerHTML = `<div class="autocomplete-empty">No results</div>`
      return
    }
    let html = ""
    items.slice(0, 5).forEach(item => {
      html += `<div class="autocomplete-item" data-autocomplete-value="${item.id}" data-autocomplete-label="${item.name.replace(/"/g, "&quot;")}">${this.highlight(item.name, query)}</div>`
    })
    if (query.length >= 2) {
      html += `<div class="autocomplete-item autocomplete-item--create" data-autocomplete-value="new_${query}" data-autocomplete-label="Create '${query}'">Create '${query}'</div>`
    }
    this.resultsTarget.innerHTML = html
  }

  highlight(text, query) {
    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "gi")
    return text.replace(regex, "<strong>$1</strong>")
  }

  keydown(e) {
    if (e.key === "ArrowDown") {
      e.preventDefault()
      this.moveSelection(1)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this.moveSelection(-1)
    } else if (e.key === "Enter") {
      const active = this.resultsTarget.querySelector(".autocomplete-item--active")
      if (active) {
        active.click()
      }
    }
  }

  moveSelection(direction) {
    const items = this.resultsTarget.querySelectorAll(".autocomplete-item:not(.autocomplete-item--create)")
    const active = this.resultsTarget.querySelector(".autocomplete-item--active")
    let idx = active ? Array.from(items).indexOf(active) : -1
    idx += direction
    if (idx < 0) idx = items.length - 1
    if (idx >= items.length) idx = 0
    items.forEach(i => i.classList.remove("autocomplete-item--active"))
    if (items[idx]) {
      items[idx].classList.add("autocomplete-item--active")
      items[idx].scrollIntoView({ block: "nearest" })
    }
  }
}
