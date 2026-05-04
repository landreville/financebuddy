# Inline Editing of Transactions - Design Spec

> **Feature:** STORY: Inline editing of transactions  
> **Date:** 2026-05-03  
> **Status:** Approved

---

## Overview

Allow users to edit transaction fields directly in the transactions table on the account page, without navigating to a separate edit form. Should support editing date, payee, category, memo, and amount inline via double-click-to-edit pattern using Turbo/Stimulus.

---

## User Flow

1. User is on an account page viewing transactions table
2. User double-clicks anywhere on a transaction row
3. All editable fields in that row become interactive (form inputs)
4. User modifies one or more fields
5. Save is triggered by:
   - Clicking "Save" button (appears in row)
   - Clicking "Cancel" button (appears in row)
   - Clicking outside the row (blur triggers save automatically)
6. After save/cancel, row returns to read-only display mode

---

## Fields to Support Editing

- **Date** (date picker)
- **Payee** (text input with autocomplete)
- **Category** (text input with autocomplete)
- **Memo** (text input)
- **Amount** (numeric input)

---

## Architecture

### Components

**InlineEditRow Stimulus Controller**
- Attached to `<tr>` element with `data-controller="inline-edit-row"`
- Manages row-level edit state (read-only vs edit mode)
- Handles double-click to enter edit mode
- Handles blur to save (with debouncing)
- Coordinates with field-specific controllers

**InlineEditField Stimulus Controllers** (per field type)
- `inline-edit-date` - date picker
- `inline-edit-autocomplete` - payee/category with autocomplete
- `inline-edit-text` - memo
- `inline-edit-amount` - numeric input

**Save/Cancel Buttons**
- Rendered in row when in edit mode
- Trigger explicit save or cancel operations

### Data Flow

```
User double-clicks row
    ↓
inline-edit-row enters edit mode
    ↓
Replace text nodes with form inputs
    ↓
User modifies fields
    ↓
Blur on row OR Save button clicked
    ↓
Serialize form data
    ↓
PATCH /api/v1/transactions/:id with updated fields
    ↓
Server returns updated transaction
    ↓
Update row display with new values
```

---

## Implementation Details

### View Changes (`app/views/accounts/show.html.erb`)

- Add `data-controller="inline-edit-row"` to `<tbody>` or individual `<tr>` elements
- Add `data-inline-edit-row-target="row"` to each row
- Add Save/Cancel buttons to row (hidden by default)
- Mark editable fields with `data-inline-edit-field-target` and field type

### Stimulus Controllers

**`inline_edit_row_controller.js`**
- `edit()` - enter edit mode
- `save()` - serialize and submit changes
- `cancel()` - discard changes, return to read-only
- `handleBlur()` - blur handler for auto-save

**Field-specific controllers**
- Each handles its own input widget and value serialization

### API Endpoint

**PATCH `/api/v1/transactions/:id`**
- Accepts partial update: `{ date: "2026-05-03", payee_id: 1, memo: "...", amount: -5000 }`
- Returns updated transaction record

---

## Edge Cases

1. **Network failure** - Show error state, allow retry
2. **Concurrent edits** - Last write wins (simple approach)
3. **Validation errors** - Highlight invalid fields, show error message
4. **Multiple rows in edit mode** - Only one row editable at a time (optional: could allow multiple)

---

## Testing Strategy

- Unit tests for Stimulus controllers
- System tests for full workflow
- Test save, cancel, blur scenarios
- Test network error handling

---

## Future Enhancements

- Support for editing multiple rows at once
- Undo/redo for accidental changes
- Field-specific validation before save
- Optimistic UI updates
