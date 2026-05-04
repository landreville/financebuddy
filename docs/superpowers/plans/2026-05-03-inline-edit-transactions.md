# Inline Editing of Transactions - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement inline editing for transaction rows in the account page, allowing users to edit date, payee, category, memo, and amount directly in the table without navigating away.

**Architecture:** Row-level Stimulus controller (`inline-edit-row`) manages edit state and coordinates with field-specific controllers. Fields use Stimulus targets and data attributes to determine their type (date, autocomplete, text, amount). Save/Cancel buttons are conditionally rendered. API PATCH endpoint updates transaction data.

**Tech Stack:** Rails 8, Hotwire, Stimulus, PostgreSQL

---

## Task 1: Create inline edit row controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_row_controller.js`
- Test: `test/javascript/controllers/inline_edit_row_test.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_row_test.js
import { inlineEditRowController } from 'controllers/inline_edit_row_controller'
import { application } from 'controllers/application'
import { getController } from '@rails/actioncable'

describe('inline-edit-row', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <table>
        <tbody>
          <tr data-controller="inline-edit-row">
            <td class="col-date">2026-05-03</td>
            <td class="col-payee">Payee Name</td>
            <td class="col-cat">Category</td>
            <td class="col-memo">Memo</td>
            <td class="col-out">50.00</td>
            <button data-inline-edit-row-target="saveBtn">Save</button>
            <button data-inline-edit-row-target="cancelBtn">Cancel</button>
          </tr>
        </tbody>
      </table>
    `
  })

  test('enters edit mode on double click', () => {
    const row = document.querySelector('tr')
    row.dispatchEvent(new Event('dblclick'))
    
    expect(row.dataset.inlineEditRowEditMode).toBe('true')
  })

  test('saves on save button click', async () => {
    const row = document.querySelector('tr')
    row.dispatchEvent(new Event('dblclick'))
    
    const saveBtn = row.querySelector('[data-inline-edit-row-target="saveBtn"]')
    saveBtn.click()
    
    expect(row.dataset.inlineEditRowEditMode).toBe('false')
  })

  test('cancels on cancel button click', () => {
    const row = document.querySelector('tr')
    row.dispatchEvent(new Event('dblclick'))
    
    const cancelBtn = row.querySelector('[data-inline-edit-row-target="cancelBtn"]')
    cancelBtn.click()
    
    expect(row.dataset.inlineEditRowEditMode).toBe('false')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_row_test.js`
Expected: FAIL with "inline_edit_row_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_row_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['saveBtn', 'cancelBtn', 'row']

  connect() {
    this.editMode = false
    this.originalData = {}
  }

  doubleClick() {
    this.enterEditMode()
  }

  enterEditMode() {
    this.editMode = true
    this.saveBtnTarget.style.display = 'inline-block'
    this.cancelBtnTarget.style.display = 'inline-block'
    
    // Store original values and replace with inputs
    this.storeOriginalData()
    this.renderInputs()
  }

  exitEditMode() {
    this.editMode = false
    this.saveBtnTarget.style.display = 'none'
    this.cancelBtnTarget.style.display = 'none'
    this.restoreDisplay()
  }

  save() {
    if (!this.editMode) return

    const formData = this.serializeFormData()
    
    fetch(`/api/v1/transactions/${this.transactionId()}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(formData)
    })
      .then(response => response.json())
      .then(data => {
        this.updateRowDisplay(data)
        this.exitEditMode()
      })
      .catch(error => {
        console.error('Save failed:', error)
        alert('Failed to save changes')
      })
  }

  cancel() {
    if (!this.editMode) return
    this.exitEditMode()
  }

  blur(event) {
    if (!this.editMode) return
    
    // Only save if click is outside the row
    if (!this.element.contains(event.relatedTarget)) {
      this.save()
    }
  }

  // Private methods
  transactionId() {
    return this.element.dataset.txnId
  }

  storeOriginalData() {
    // Store current text content for each field
    this.originalData = {
      date: this.element.querySelector('.col-date').textContent,
      payee: this.element.querySelector('.col-payee').textContent,
      category: this.element.querySelector('.col-cat').textContent,
      memo: this.element.querySelector('.col-memo').textContent,
      out: this.element.querySelector('.col-out').textContent,
      inflow: this.element.querySelector('.col-in').textContent
    }
  }

  renderInputs() {
    const dateCell = this.element.querySelector('.col-date')
    const payeeCell = this.element.querySelector('.col-payee')
    const catCell = this.element.querySelector('.col-cat')
    const memoCell = this.element.querySelector('.col-memo')
    const outCell = this.element.querySelector('.col-out')
    const inflowCell = this.element.querySelector('.col-in')

    // Replace content with input elements
    dateCell.innerHTML = this.dateInput(this.originalData.date)
    payeeCell.innerHTML = this.autocompleteInput('payee', this.originalData.payee)
    catCell.innerHTML = this.autocompleteInput('category', this.originalData.category)
    memoCell.innerHTML = this.textInput('memo', this.originalData.memo)
    outCell.innerHTML = this.amountInput('out', this.originalData.out)
    inflowCell.innerHTML = this.amountInput('inflow', this.originalData.inflow)
  }

  restoreDisplay() {
    const dateCell = this.element.querySelector('.col-date')
    const payeeCell = this.element.querySelector('.col-payee')
    const catCell = this.element.querySelector('.col-cat')
    const memoCell = this.element.querySelector('.col-memo')
    const outCell = this.element.querySelector('.col-out')
    const inflowCell = this.element.querySelector('.col-in')

    dateCell.textContent = this.originalData.date
    payeeCell.textContent = this.originalData.payee
    catCell.textContent = this.originalData.category
    memoCell.textContent = this.originalData.memo
    outCell.textContent = this.originalData.out
    inflowCell.textContent = this.originalData.inflow
  }

  serializeFormData() {
    const formData = {}
    
    const dateInput = this.element.querySelector('[name="date"]')
    if (dateInput) formData.date = dateInput.value

    const payeeInput = this.element.querySelector('[name="payee_id"]')
    if (payeeInput) formData.payee_id = payeeInput.value

    const categoryInput = this.element.querySelector('[name="category_id"]')
    if (categoryInput) formData.category_id = categoryInput.value

    const memoInput = this.element.querySelector('[name="memo"]')
    if (memoInput) formData.memo = memoInput.value

    const outInput = this.element.querySelector('[name="amount_out"]')
    if (outInput) formData.amount = -Math.abs(parseFloat(outInput.value) || 0)

    const inflowInput = this.element.querySelector('[name="amount_in"]')
    if (inflowInput) formData.amount = parseFloat(inflowInput.value) || 0

    return formData
  }

  updateRowDisplay(transaction) {
    const dateCell = this.element.querySelector('.col-date')
    const payeeCell = this.element.querySelector('.col-payee')
    const catCell = this.element.querySelector('.col-cat')
    const memoCell = this.element.querySelector('.col-memo')
    const outCell = this.element.querySelector('.col-out')
    const inflowCell = this.element.querySelector('.col-in')

    dateCell.textContent = transaction.date
    payeeCell.textContent = transaction.payee?.name || '—'
    
    // Category logic - need to find other account's category
    catCell.textContent = transaction.category?.name || '—'
    
    memoCell.textContent = transaction.memo || ''
    
    const amount = transaction.amount || 0
    if (amount < 0) {
      outCell.textContent = Math.abs(amount).toFixed(2)
      inflowCell.textContent = ''
    } else {
      outCell.textContent = ''
      inflowCell.textContent = amount.toFixed(2)
    }
  }

  // Input renderers
  dateInput(value) {
    return `<input type="date" name="date" value="${value}" class="edit-input" data-inline-edit-field-target="field" data-action="blur->inline-edit-row#blur">`
  }

  autocompleteInput(name, value) {
    return `<input type="text" name="${name === 'payee' ? 'payee_id' : 'category_id'}" value="${value}" data-inline-edit-field-target="field" data-action="blur->inline-edit-row#blur" class="edit-input autocomplete">`
  }

  textInput(name, value) {
    return `<input type="text" name="${name}" value="${value}" data-inline-edit-field-target="field" data-action="blur->inline-edit-row#blur" class="edit-input">`
  }

  amountInput(name, value) {
    return `<input type="number" name="amount_${name}" value="${value}" data-inline-edit-field-target="field" data-action="blur->inline-edit-row#blur" class="edit-input amount">`
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_row_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_row_controller.js test/javascript/controllers/inline_edit_row_test.js
git commit -m "feat: add inline-edit-row Stimulus controller"
```

---

## Task 2: Create inline edit field base controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_field_controller.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_field_test.js
import { inlineEditFieldController } from 'controllers/inline_edit_field_controller'
import { application } from 'controllers/application'

describe('inline-edit-field', () => {
  test('is a Stimulus controller', () => {
    expect(inlineEditFieldController).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_field_test.js`
Expected: FAIL with "inline_edit_field_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_field_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['field']

  connect() {
    // Base controller - field types extend this
  }

  initialize() {
    // Initialization logic if needed
  }

  // Field-specific validation can be added here
  validate() {
    return true
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_field_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_field_controller.js
git commit -m "feat: add inline-edit-field base Stimulus controller"
```

---

## Task 3: Create inline edit date controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_date_controller.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_date_test.js
import { inlineEditDateController } from 'controllers/inline_edit_date_controller'

describe('inline-edit-date', () => {
  test('is a Stimulus controller', () => {
    expect(inlineEditDateController).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_date_test.js`
Expected: FAIL with "inline_edit_date_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_date_controller.js
import { Controller } from '@hotwired/stimulus'
import InlineEditFieldController from 'controllers/inline_edit_field_controller'

export default class extends InlineEditFieldController {
  static targets = ['field']

  connect() {
    super.connect()
    this.fieldTarget.type = 'date'
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_date_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_date_controller.js
git commit -m "feat: add inline-edit-date Stimulus controller"
```

---

## Task 4: Create inline edit autocomplete controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_autocomplete_controller.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_autocomplete_test.js
import { inlineEditAutocompleteController } from 'controllers/inline_edit_autocomplete_controller'

describe('inline-edit-autocomplete', () => {
  test('is a Stimulus controller', () => {
    expect(inlineEditAutocompleteController).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_autocomplete_test.js`
Expected: FAIL with "inline_edit_autocomplete_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_autocomplete_controller.js
import { Controller } from '@hotwired/stimulus'
import InlineEditFieldController from 'controllers/inline_edit_field_controller'

export default class extends InlineEditFieldController {
  static targets = ['field']

  connect() {
    super.connect()
    this.fieldTarget.type = 'text'
    this.fieldTarget.placeholder = 'Type to search...'
  }

  // Optional: Add debounced search functionality
  // This could call /api/v1/payees/search?query=...
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_autocomplete_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_autocomplete_controller.js
git commit -m "feat: add inline-edit-autocomplete Stimulus controller"
```

---

## Task 5: Create inline edit text controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_text_controller.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_text_test.js
import { inlineEditTextController } from 'controllers/inline_edit_text_controller'

describe('inline-edit-text', () => {
  test('is a Stimulus controller', () => {
    expect(inlineEditTextController).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_text_test.js`
Expected: FAIL with "inline_edit_text_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_text_controller.js
import { Controller } from '@hotwired/stimulus'
import InlineEditFieldController from 'controllers/inline_edit_field_controller'

export default class extends InlineEditFieldController {
  static targets = ['field']

  connect() {
    super.connect()
    this.fieldTarget.type = 'text'
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_text_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_text_controller.js
git commit -m "feat: add inline-edit-text Stimulus controller"
```

---

## Task 6: Create inline edit amount controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_amount_controller.js`

- [ ] **Step 1: Write the failing test**

```javascript
// test/javascript/controllers/inline_edit_amount_test.js
import { inlineEditAmountController } from 'controllers/inline_edit_amount_controller'

describe('inline-edit-amount', () => {
  test('is a Stimulus controller', () => {
    expect(inlineEditAmountController).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/javascript/controllers/inline_edit_amount_test.js`
Expected: FAIL with "inline_edit_amount_controller.js not found"

- [ ] **Step 3: Write minimal implementation**

```javascript
// app/javascript/controllers/inline_edit_amount_controller.js
import { Controller } from '@hotwired/stimulus'
import InlineEditFieldController from 'controllers/inline_edit_field_controller'

export default class extends InlineEditFieldController {
  static targets = ['field']

  connect() {
    super.connect()
    this.fieldTarget.type = 'number'
    this.fieldTarget.step = '0.01'
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/javascript/controllers/inline_edit_amount_test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/inline_edit_amount_controller.js
git commit -m "feat: add inline-edit-amount Stimulus controller"
```

---

## Task 7: Update accounts show view

**Files:**
- Modify: `app/views/accounts/show.html.erb`

- [ ] **Step 1: Update the view to add Stimulus targets**

Read current view first:

```erb
<%= render "shared/sidebar", sidebar_accounts: @sidebar_accounts, current_account: @account %>

<div class="main">
  <div class="main__head">
    <div>
      <h1 class="main__title"><%= @account.name %></h1>
      <div class="main__sub">// Working Balance · <%= fmt_money(@account.balance) %></div>
    </div>
    <div class="main__balrow">
      <div class="main__balcell cleared">
        <div class="lbl">Cleared</div>
        <div class="val"><%= fmt_money(@account.cleared_balance) %></div>
      </div>
      <div class="main__balcell uncleared">
        <div class="lbl">Uncleared</div>
        <div class="val"><%= fmt_money(@account.balance - @account.cleared_balance) %></div>
      </div>
      <div class="main__balcell">
        <div class="lbl">Working</div>
        <div class="val"><%= fmt_money(@account.balance) %></div>
      </div>
    </div>
  </div>

  <div class="tb">
    <%= link_to "＋ ADD TXN", "#", class: "btn btn--primary" %>
    <button class="btn">EDIT</button>
    <button class="btn">FILE ▾</button>
    <input type="text" placeholder="search payees, memos, categories...">
    <div class="spacer"></div>
    <span class="meta"><%= @transactions.size %> rows</span>
    <button class="btn">⇩ EXPORT</button>
    <button class="btn">⟳ RECONCILE</button>
  </div>

  <div class="ledger">
    <table>
      <colgroup>
        <col class="col-status">
        <col class="col-date">
        <col class="col-payee">
        <col class="col-cat">
        <col class="col-memo">
        <col class="col-out">
        <col class="col-in">
      </colgroup>
      <thead>
        <tr>
          <th class="col-status">✓</th>
          <th class="col-date">Date</th>
          <th class="col-payee">Payee</th>
          <th class="col-cat">Category</th>
          <th class="col-memo">Memo</th>
          <th class="col-out" style="text-align: right">Outflow</th>
          <th class="col-in" style="text-align: right">Inflow</th>
        </tr>
      </thead>
      <tbody data-controller="inline-edit-row" data-action="blur->inline-edit-row#blur">
        <% @transactions.each do |txn| %>
        <% line = txn.transaction_lines.find { |l| l.account_id == @account.id } %>
        <% next unless line %>
        <tr data-txn-id="<%= txn.id %>" data-inline-edit-row-target="row">
          <td class="col-status">
            <span class="st <%= txn.status == 'cleared' ? 'cleared' : (txn.status == 'reconciled' ? 'recon' : '') %>">
              <%= txn.status == 'cleared' ? 'C' : (txn.status == 'reconciled' ? 'R' : '·') %>
            </span>
          </td>
          <td class="col-date"><%= txn.date.strftime("%y-%m-%d") %></td>
          <td class="col-payee"><%= txn.payee&.name || txn.entry_type.titleize %></td>
          <% other_line = txn.transaction_lines.find { |l| l.account_id != @account.id } %>
          <td class="col-cat"><%= @categories_by_account[other_line&.account_id]&.name || "—" %></td>
          <td class="col-memo"><%= txn.memo %></td>
          <% if line.amount < 0 %>
          <td class="col-out has"><%= fmt_money(line.amount.abs) %></td>
          <td class="col-in"></td>
          <% else %>
          <td class="col-out"></td>
          <td class="col-in has"><%= fmt_money(line.amount) %></td>
          <% end %>
          <td>
            <button data-inline-edit-row-target="saveBtn" style="display:none">Save</button>
            <button data-inline-edit-row-target="cancelBtn" style="display:none">Cancel</button>
          </td>
        </tr>
        <% end %>
        <% if @transactions.empty? %>
        <tr>
          <td colspan="8" style="padding: 24px; text-align: center; color: var(--muted);">
            — NO TRANSACTIONS —
          </td>
        </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add app/views/accounts/show.html.erb
git commit -m "feat: add inline editing UI to accounts show view"
```

---

## Task 8: Create API endpoint for transaction updates

**Files:**
- Create: `app/controllers/api/v1/transactions_controller.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# test/controllers/api/v1/transactions_controller_test.rb
require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ledger = ledgers(:one)
    @user = users(:one)
    @transaction = transactions(:one)
  end

  test "updates transaction with valid attributes" do
    sign_in @user
    
    patch api_v1_transaction_path(@transaction), params: { 
      date: "2026-05-03",
      memo: "Updated memo",
      payee_id: payees(:one).id 
    }
    
    assert_response :success
    @transaction.reload
    assert_equal "2026-05-03", @transaction.date.to_s
    assert_equal "Updated memo", @transaction.memo
  end

  test "returns error for invalid attributes" do
    sign_in @user
    
    patch api_v1_transaction_path(@transaction), params: { date: "invalid" }
    
    assert_response :unprocessable_entity
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/api/v1/transactions_controller_test.rb`
Expected: FAIL with "routes not configured"

- [ ] **Step 3: Add API routes**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", :as => :rails_health_check

  get "dashboard" => "dashboard#index", as: :dashboard
  get "budget" => "budget#index", as: :budget
  resources :accounts, only: [:index, :show]
  get "reports" => "reports#index", as: :reports
  resources :recurring_transactions, only: [:index], path: "recurring"

  namespace :api do
    namespace :v1 do
      resources :transactions, only: [:update]
    end
  end

  root "home#index"
end
```

- [ ] **Step 4: Create API controller**

```ruby
# app/controllers/api/v1/transactions_controller.rb
module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :set_transaction

      def update
        if @transaction.update(transaction_params)
          render json: @transaction, include: [:payee, :transaction_lines]
        else
          render json: @transaction.errors, status: :unprocessable_entity
        end
      end

      private

      def set_transaction
        @transaction = Current.ledger.transaction_entries.find(params[:id])
      end

      def transaction_params
        params.permit(:date, :memo, :payee_id, :category_id, :amount)
      end
    end
  end
end
```

- [ ] **Step 5: Run test to verify it fails**

Run: `bin/rails test test/controllers/api/v1/transactions_controller_test.rb`
Expected: FAIL with "transactions not found"

- [ ] **Step 6: Create fixture**

Add to `test/fixtures/transactions.yml`:

```yaml
one:
  ledger: one
  date: 2026-01-01
  entry_type: expense
  status: uncleared
  memo: Test transaction
```

- [ ] **Step 7: Run test to verify it passes**

Run: `bin/rails test test/controllers/api/v1/transactions_controller_test.rb`
Expected: All tests pass

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb app/controllers/api/v1/transactions_controller.rb test/controllers/api/v1/transactions_controller_test.rb
git commit -m "feat: add API endpoint for transaction updates"
```

---

## Task 9: Add CSS styles for editable fields

**Files:**
- Modify: `app/assets/stylesheets/application.tailwind.css` (or existing CSS file)

- [ ] **Step 1: Add styles**

```css
/* app/assets/stylesheets/application.tailwind.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

.edit-input {
  @apply w-full px-2 py-1 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500;
}

.edit-input:focus {
  @apply border-blue-500;
}

.autocomplete {
  @apply cursor-pointer;
}
```

- [ ] **Step 2: Commit**

```bash
git add app/assets/stylesheets/application.tailwind.css
git commit -m "feat: add styles for inline edit inputs"
```

---

## Task 10: System test for full workflow

**Files:**
- Create: `test/system/inline_editing_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# test/system/inline_editing_test.rb
require "application_system_test_case"

class InlineEditingTest < ApplicationSystemTestCase
  setup do
    @ledger = ledgers(:one)
    @account = accounts(:one)
    @transaction = transactions(:one)
    
    login_as users(:one), scope: :user
    visit account_path(@account)
  end

  test "user can edit transaction row" do
    visit account_path(@account)
    
    # Find the transaction row
    row = find("tr[data-txn-id='#{@transaction.id}']")
    
    # Double click to enter edit mode
    row.double_click
    
    # Verify inputs are visible
    assert_has_selector 'input[name="date"]'
    assert_has_selector 'input[name="payee_id"]'
    
    # Edit the date
    fill_in 'date', with: '2026-05-15'
    
    # Click save
    click_button 'Save'
    
    # Verify changes persisted
    assert_has_text '26-05-15', wait: 2
  end

  test "user can cancel editing" do
    visit account_path(@account)
    
    row = find("tr[data-txn-id='#{@transaction.id}']")
    row.double_click
    
    # Edit but don't save
    fill_in 'memo', with: 'Edited memo'
    
    click_button 'Cancel'
    
    # Verify original memo is restored
    assert_has_text @transaction.memo, wait: 2
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/system/inline_editing_test.rb`
Expected: FAIL with missing test helpers or fixtures

- [ ] **Step 3: Run test to verify it passes**

After fixing any issues, run again:
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add test/system/inline_editing_test.rb
git commit -m "test: add system tests for inline editing"
```

---

## Final Verification

- [ ] **Step 1: Run all tests**

Run: `bin/rails test`
Expected: All tests pass

- [ ] **Step 2: Run linting**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 3: Commit final changes**

```bash
git add -A
git commit -m "feat: implement inline editing of transactions"
```

- [ ] **Step 4: Push branch**

```bash
git push origin inline-edit-transactions
```

---

## Plan Complete

Plan saved to `docs/superpowers/plans/2026-05-03-inline-edit-transactions.md`.

**Execution options:**

**1. Subagent-Driven (recommended)** - Dispatch fresh subagent per task with review checkpoints

**2. Inline Execution** - Execute tasks in this session with checkpoints

**Which approach?**
