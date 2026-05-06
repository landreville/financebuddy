# Inline Editing of Transactions — Design

**Story:** Vikunja #15 (EPIC: FinanceBuddy)
**Date:** 2026-05-06

## Goal

Let users edit transaction fields directly in the transactions table on the
account page, without navigating away. Click a row to enter edit mode; edit
date, payee, category, memo, and amount; save by clicking Save, pressing Enter,
or moving focus outside the row. Cancel with the Cancel button or Escape.

## Scope

### In scope

- Row-level click-to-edit on the transactions table in `app/views/accounts/show.html.erb`.
- Editable fields: `date`, `payee` (with autocomplete + create-new), `category`
  (with autocomplete + create-new, with transfer→expense/income conversion),
  `memo`, `amount` (separate `Out` and `In` inputs).
- Save triggers: explicit Save button, Enter key, or focus moving outside the
  row. Cancel button (and Escape key) reverts to read-only and discards typed
  values.
- Reconciled rows are non-editable. Clicking a reconciled row does nothing; a
  small lock affordance is shown.
- Validation errors keep the row in edit mode with field-level messages and
  preserve user input.
- Adds a sum-to-zero validation on `TransactionEntry`. The model currently has
  no such validation despite the double-entry convention; the inline-edit logic
  is the right moment to enforce it.
- Establishes the first real Turbo Frame patterns in the app. (Turbo Streams
  not yet needed; can be added later if a save needs to also update sibling
  DOM such as an account balance footer.)
- Establishes the first non-scaffold Stimulus controllers.
- Establishes Playwright as the end-to-end test framework: wire up the
  `webServer` block, set a `baseURL`, add a test-data seeding strategy.

### Out of scope

- Editing the visible account (changing one side of the entry away from the
  account whose page we're on).
- Editing `entry_type` or `status` directly. `entry_type` is derived from the
  offsetting account; `status` is changed via reconciliation (story #22).
- Adding new transactions (story #21).
- Optimistic locking / conflict detection — last write wins.
- Bulk edit (story #19).
- Inline edit for transactions with more than two lines. Such entries do not
  enter edit mode in this version (the row click is a no-op or shows a hint).

## Data Model

### Schema changes

None. All fields exist:

- `transactions.date`, `transactions.payee_id`, `transactions.entry_type`,
  `transactions.status`, `transactions.memo`.
- `transaction_lines.account_id`, `transaction_lines.amount`.

### Model changes

`app/models/transaction_entry.rb`:

- Add `validate :lines_sum_to_zero`. Sums `transaction_lines.map(&:amount)`,
  errors on the entry if non-zero. Skipped when `transaction_lines` is empty
  (a transient state during build).
- Add an `entry_type` recompute helper used by the updater service:
  - `transfer` if both lines' accounts are in `Account::USER_ACCOUNT_TYPES`.
  - `expense` if the offsetting account is an `expense` system account.
  - `income` if `revenue`.

## Routes

`config/routes.rb`:

```ruby
resources :transactions, only: [:edit, :update]
resources :payees,       only: [:index]
resources :categories,   only: [:index]
```

All scoped to the current ledger inside the controllers.

## Controllers

### `TransactionsController` (new)

- `#edit` — ledger-scopes the entry. If `status == "reconciled"` (or the entry
  has more than two lines), responds 403 with `_row.html.erb` re-rendered
  inside the matching Turbo Frame (so a stale UI silently snaps back to
  read-only). Otherwise renders an HTML response containing
  `<%= turbo_frame_tag dom_id(txn) do %><%= render "transactions/edit_row",
  ... %><% end %>`. Turbo extracts the matching frame and swaps it in.
- `#update` — ledger-scopes the entry, calls `TransactionUpdater`. Responds
  with HTML in the matching Turbo Frame:
  - On success (`200`): re-render `transactions/_row.html.erb` (read-only)
    inside the frame.
  - On failure (`422`): re-render `transactions/_edit_row.html.erb` with errors
    and submitted values preserved, inside the frame.

No `*.turbo_stream.erb` views are needed; Turbo Frames swap matching frame
contents from any HTML response. (Turbo Streams could be added later if an
update needs to also update sibling DOM, e.g. an account balance footer.)

Strong params: `:date`, `:memo`, `:payee_name`, `:category_name`,
`:out_amount`, `:in_amount`.

### `PayeesController#index` (new)

Returns `[{id, name}]` JSON, filtered by `?q=` substring (case-insensitive),
scoped to the current ledger. Used by the payee autocomplete.

### `CategoriesController#index` (new)

Returns `[{id, name, account_id}]` JSON, filtered by `?q=` substring, scoped
to the current ledger. Used by the category autocomplete.

The autocomplete endpoints are deliberately tiny — name + id only — so the
Stimulus controller stays simple.

## TransactionUpdater Service

**File:** `app/services/transaction_updater.rb`

### Interface

```ruby
TransactionUpdater.new(
  transaction_entry,
  visible_account: account,
  params: {
    date:, memo:, payee_name:, category_name:,
    out_amount:, in_amount:
  }
).call  # returns true/false; populates errors on the entry
```

The controller hands the updater the entry, the account whose page we're on
(so the updater knows which line is "this side"), and a normalized params hash.

### Behaviour

All inside one `ActiveRecord::Base.transaction`:

1. **Reject if reconciled.** If `transaction_entry.status == "reconciled"`,
   add a base error and return false.
2. **Update entry scalars** — `date`, `memo`.
3. **Resolve payee**:
   - If `payee_name` is blank, set `payee_id = nil`.
   - Otherwise `Payee.find_or_create_by(name: payee_name.strip, ledger: ledger)`.
4. **Resolve category** (operates on the offsetting line, i.e. the line whose
   `account_id != visible_account.id`):
   - If `category_name` is blank, leave the offsetting line's account
     untouched (and therefore the entry_type as-is).
   - If `category_name` matches an existing `Category` in the ledger
     (case-insensitive name match), set the offsetting line's `account_id`
     to that Category's `account_id`.
   - If `category_name` matches no Category, create:
     - `Account.create!(name: category_name, account_type: "expense", ledger:)`
     - `Category.create!(name: category_name, account: <new account>)`
     - Then point the offsetting line at the new account.
   - If the entry was previously a transfer (offsetting line's account was
     a user account), this swap converts it to an expense/income.
5. **Update amounts:**
   - Interpret `out_amount` and `in_amount`. The non-blank one wins; if both
     are non-blank, `in_amount` wins (matches the user's last-typed input
     semantics; the form controller blanks the other input on focus).
   - `out` populates a negative amount; `in` populates positive.
   - Set the visible-side line's `amount` to that value, and the offsetting
     line's `amount` to its negation.
6. **Recompute `entry_type`** based on the (possibly new) offsetting account's
   type, using the helper added to `TransactionEntry`.
7. **Save entry and lines.** The sum-to-zero validation enforces correctness;
   if anything fails, the transaction rolls back and `false` is returned with
   errors on the entry.

### Error surface

Errors are attached to `transaction_entry.errors` keyed by form field name:
`:date`, `:memo`, `:payee_name`, `:category_name`, `:out_amount`, `:in_amount`,
plus `:base` for sum-to-zero or reconciled-lock. The controller re-renders the
edit row with these errors highlighted.

## Views

### Frame structure

Extract the row from `accounts/show.html.erb` into two partials wrapped in a
Turbo Frame.

```
app/views/transactions/
  _row.html.erb        # read-only <tr>
  _edit_row.html.erb   # editable <tr> with form, inputs, Save/Cancel
```

In `accounts/show.html.erb`, the loop becomes:

```erb
<% @transactions.each do |txn| %>
  <%= turbo_frame_tag dom_id(txn) do %>
    <%= render "transactions/row",
               txn:, account: @account,
               categories_by_account: @categories_by_account %>
  <% end %>
<% end %>
```

### `_row.html.erb` (read-only)

The existing `<tr>` markup, with:

- `data-controller="row-edit"`.
- `data-row-edit-url-value="<%= edit_transaction_path(txn) %>"`.
- `data-locked` attribute when `status == "reconciled"`. The Stimulus
  controller no-ops the click; a small lock glyph is rendered in the status
  cell.
- `data-multi-line` attribute when `transaction_lines.count > 2`. The
  controller no-ops the click for these too.

### `_edit_row.html.erb` (editable)

A `<tr>` containing one `form_with model: txn, url: transaction_path(txn),
method: :patch, data: { controller: "row-edit-form", ... }`, with inputs in
cells matching the read-only column widths.

| Cell    | Input                                                              |
| ------- | ------------------------------------------------------------------ |
| status  | Read-only — same status pill as the read-only row.                 |
| date    | `<input type="date" name="date">`.                                 |
| payee   | Text input + `autocomplete` Stimulus wrapper. `name="payee_name"`. |
| category| Text input + `autocomplete` Stimulus wrapper. `name="category_name"`. Always editable, even on transfers (picking a category converts the entry). |
| memo    | Text input. `name="memo"`.                                         |
| out     | Numeric input, `step="0.01"`. `name="out_amount"`.                 |
| in      | Numeric input, `step="0.01"`. `name="in_amount"`.                  |

Save and Cancel buttons render in a floating `<div class="row-edit-actions">`
positioned absolutely against the right edge of the `<tr>` so the table's
fixed `colgroup` widths don't have to widen. `Save` uses `.btn--primary`;
`Cancel` uses `.btn--ghost`.

Field error rendering: under each input cell, an empty
`<div class="field-error" data-row-edit-form-target="errorDate">`
(and `errorMemo`, `errorPayeeName`, etc.). The form controller fills these
when the server responds with errors.

### Frame replacement on save

- Success: `TransactionsController#update` responds with HTML wrapping the
  freshly-rendered `_row.html.erb` partial in a `<%= turbo_frame_tag dom_id(txn) %>`.
  Turbo extracts the matching frame and swaps the row back to read-only.
- Failure: responds 422 with HTML wrapping `_edit_row.html.erb` (with error
  messages and submitted values preserved) in the same frame tag.

## Stimulus Controllers

Three small controllers, one purpose each.

### `app/javascript/controllers/row_edit_controller.js`

Attached to the read-only `<tr>`. Job: enter edit mode.

- Values: `urlValue` (`edit_transaction_path`).
- Action: `click → enterEdit`.
- Behaviour: if `data-locked` or `data-multi-line` is present, no-op.
  Otherwise sets the inner `<turbo-frame src=urlValue>` so Turbo fetches the
  edit row partial and swaps it into the frame.

### `app/javascript/controllers/row_edit_form_controller.js`

Attached to the `<form>` inside the edit row. Job: submit-on-blur, explicit
save/cancel, error rendering.

- Targets: `input` (all editable fields), one `error<Field>` target per field.
- Actions:
  - `focusout@window → maybeSave` — checks if `event.relatedTarget` is inside
    `this.element`. If yes, it's a tab between fields — do nothing. If no
    (focus left the row entirely), call `submit()`.
  - `submit:start` clears any field errors.
  - `submit:end` is a no-op (the Turbo Stream response handles the swap).
  - `keydown.enter → submit` (with `preventDefault`).
  - `keydown.escape → cancel` — refetches the read-only partial into the
    frame, discarding typed values.
  - `clickSave → submit`.
  - `clickCancel → cancel`.
  - On `input` to `out_amount`, blank `in_amount` (and vice versa) so only
    one side carries a value at submit time.
- Guards against double-submission with a `submitting` flag.

### `app/javascript/controllers/autocomplete_controller.js`

Attached to the wrapper around payee and category text inputs. Job: type-ahead
suggestions plus a "Create '…'" option.

- Values: `urlValue` (`/payees.json` or `/categories.json`), `paramValue`
  (`q`), `allowCreateValue` (boolean).
- Targets: `input` (visible text input), `list` (popover `<ul>`).
- Actions:
  - `input → fetchSuggestions` (debounced ~150ms). GETs `urlValue?q=…` and
    renders matches as `<li>` items. If `allowCreateValue` is true and the
    typed text matches none, append a final `<li>` "Create '…'".
  - `keydown.arrowdown` / `keydown.arrowup` — move highlight.
  - `keydown.enter` — select highlighted item; sets the input's value to the
    item's name and closes the popover. The form-controller's Enter handler
    then submits.
  - `mousedown` on an item — select (using mousedown not click so it fires
    before the input's blur).
  - `focusout` — close the popover (with a small delay so a click on the
    list registers).
- The popover is an `<ul>` rendered absolutely below the input, `z-index: 10`,
  with max-height and scroll.

### Keyboard summary

| Key         | Behaviour                                                        |
| ----------- | ---------------------------------------------------------------- |
| Tab / Shift-Tab | Move between fields within the row. No save.                 |
| Enter       | Save. If autocomplete is open with a highlighted suggestion, select it first. |
| Escape      | Cancel. Revert to read-only row. Discard typed values.           |
| Click outside row | Auto-save.                                                 |

## Validation & Error Handling

- All validation errors keep the row in edit mode and preserve typed values.
- Field-level errors (e.g. `payee_name`) render under the corresponding cell
  in red, using the `--red` design token, at `--fz-xs` size.
- Base errors (`:base`) render in a small bar above the row's action buttons.
- Reconciled-lock attempts are caught both in the UI (the controller no-ops
  the click) and in the updater service (returns false with a base error). The
  redundant server check protects against stale frames.

## Tests

### Minitest

`test/models/transaction_entry_test.rb` — extend with sum-to-zero cases:

- Balanced lines pass.
- Unbalanced lines fail.
- Empty `transaction_lines` collection passes (transient build state).

`test/services/transaction_updater_test.rb` (new) — covers:

- Simple memo / date / amount edit on an expense.
- Payee change to an existing payee.
- Payee change to a new name → creates payee.
- Category change to an existing category → swaps offsetting line's account.
- Category change to a new name → creates an Account and a Category.
- Category set on a transfer → converts the entry to an expense (entry_type
  recomputed).
- Blank `category_name` leaves the offsetting line untouched.
- Reconciled entry → returns false, errors, no DB change.
- Sum-to-zero violation → rolls back the transaction.
- Amount sign: `out` input populates a negative line; `in` input populates
  a positive line; the offsetting line's amount is the negation.

### Playwright (end-to-end)

Wire up `playwright.config.ts`:

- Uncomment the `webServer` block. Run `bin/rails server -e test -p 3001`.
- Set `baseURL: 'http://localhost:3001'`.

Test data: a `bin/rails playwright:seed` Rake task that wipes the test DB
and inserts a known ledger, account, payees, categories, and a few
transactions (one expense, one income, one transfer, one reconciled). Called
from a Playwright global setup. The Rake task is preferred over a TS-only
seeder because it can reuse the same fixture data the Minitest suite uses.

Auth: a test-only `/test/login?user_id=…` endpoint guarded by `Rails.env.test?`
that establishes a session cookie. Playwright helper calls it before each
spec.

Specs in `tests/transactions/`:

- `inline_edit.spec.ts` — open account page; click row; expect inputs visible;
  change memo; click outside; expect read-only row shows new memo.
- `inline_edit_payee.spec.ts` — type new payee name; pick "Create 'Foo'";
  save; expect new payee persists (assertable via the same row reloaded or a
  payees JSON probe).
- `inline_edit_category.spec.ts` — change category on a transfer row; expect
  entry_type becomes expense (visible via the amount column behaviour and a
  reload of the row).
- `inline_edit_validation.spec.ts` — clear the date; blur; expect an error
  under date and the row stays in edit mode.
- `inline_edit_reconciled.spec.ts` — click a reconciled row; expect no edit
  mode entered.
- `inline_edit_keyboard.spec.ts` — tab between fields stays in edit mode;
  Enter saves; Escape cancels.

Replace the demo `tests/example.spec.ts` (delete it).

CI: `.github/workflows/playwright.yml` already runs on push and PR, so the
new specs are picked up automatically.

## Styling

Add `app/assets/stylesheets/components/_inline_edit.scss`, imported from
`application.bootstrap.scss`.

- `tr.is-editing` — `--paper-2` background and a `--shadow-bevel-in` outline,
  mirroring the existing `tr.is-selected` treatment.
- Inputs sized to fit cells:
  `height: calc(var(--row-h) - 8px); width: 100%; border: 0;
   background: transparent; font: inherit;`
  so the table doesn't reflow.
- `.field-error` — `font-size: var(--fz-xs); color: var(--red);
   position: absolute;` so it doesn't change row height.
- `.row-edit-actions` floating bar — `position: absolute; right: 0; top: 0;
   height: var(--row-h); display: flex; gap: 4px; padding: 4px;` with
  `.btn--primary` Save and `.btn--ghost` Cancel.
- `.autocomplete-popover ul` — `position: absolute; z-index: 10;
   max-height: 200px; overflow-y: auto;` with hover highlight on items.
- Reconciled-row lock affordance — small lock glyph in the status pill,
  `cursor: not-allowed` on the row.

Honours the existing monochrome paper/ink design tokens. No new colours.

## File Inventory (new and modified)

### New

- `app/controllers/transactions_controller.rb`
- `app/controllers/payees_controller.rb`
- `app/controllers/categories_controller.rb`
- `app/services/transaction_updater.rb`
- `app/views/transactions/_row.html.erb`
- `app/views/transactions/_edit_row.html.erb`
- `app/javascript/controllers/row_edit_controller.js`
- `app/javascript/controllers/row_edit_form_controller.js`
- `app/javascript/controllers/autocomplete_controller.js`
- `app/assets/stylesheets/components/_inline_edit.scss`
- `lib/tasks/playwright.rake` (seed task)
- `tests/support/auth.ts` (helper)
- `tests/transactions/*.spec.ts` (six specs above)
- `test/services/transaction_updater_test.rb`

### Modified

- `config/routes.rb` — three new resources.
- `app/models/transaction_entry.rb` — sum-to-zero validation, entry_type helper.
- `app/views/accounts/show.html.erb` — replace the inline row with frame + partial.
- `app/assets/stylesheets/application.bootstrap.scss` — import the new component.
- `app/javascript/controllers/index.js` — auto-loaded; no manual change needed.
- `playwright.config.ts` — `webServer` block, `baseURL`.
- `test/models/transaction_entry_test.rb` — sum-to-zero cases.
- A small test-only auth route in `config/routes.rb` and matching controller,
  guarded by `Rails.env.test?`.

### Deleted

- `tests/example.spec.ts` — Playwright demo.
