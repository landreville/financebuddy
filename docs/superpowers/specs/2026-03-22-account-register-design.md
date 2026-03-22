# Account Register View — Design Spec

**Date:** 2026-03-22
**Status:** Approved
**Pencil Frame:** "F-Buddy: Account Register" in `pencil-welcome-desktop.pen`

## Overview

The Account Register is the primary screen for viewing and managing transactions within a specific financial account. It combines a sidebar listing all accounts with a data-dense transaction table as the main content area.

## Layout Structure

**Resolution:** 1440×900 (desktop only — responsive behavior is deferred to a future iteration)
**Stack:** Rails 8, Bootstrap, AlpineJS

### Top Navigation Bar (48px height)

A single dark bar (`#212529`) with three zones:

- **Left (160px):** Brand — "F-Buddy" (Space Grotesk 17px bold, white) + "F as in finance" (Inter 11px italic, `#868e96`)
- **Center (fill):** Primary navigation links — Dashboard, Budget, **Accounts** (active), Reports, Recurring. Active item: white text with blue (`#339af0`) underline. Inactive: `#868e96`.
- **Right (160px):** Quick actions — "+ Transaction" button (blue `#339af0` fill, white text, 4px radius) and "Import" text link (`#868e96`).

### Body (fills remaining height)

Horizontal layout: Sidebar (220px fixed) + Main Content (fill).

---

## Sidebar (220px)

**Background:** `#f8f9fa`
**Right border:** 1px `#dee2e6`
**Padding:** 12px
**Gap:** 8px between all children

Accounts are grouped by **budget status** (On-Budget / Tracking), then by **account type** within each group.

### On-Budget Section

**Label:** "ON-BUDGET" — Space Grotesk 10px bold, `#339af0`, uppercase, 1px letter-spacing

#### Cash Accounts
- **Sub-label:** "CASH" — Space Grotesk 10px semibold, `#868e96`, uppercase
- Account rows: horizontal layout, name left (Inter 12px) + balance right (Space Grotesk 12px)
- **Selected account:** highlighted with `#e7f5ff` background, 4px radius, name in 500 weight
- **Group total:** right-aligned, `#868e96`, 11px

#### Credit Accounts
- **Sub-label:** "CREDIT" — same style as Cash
- Negative balances shown in red (`#c92a2a`)
- **Group total:** right-aligned, red for negative

### Divider
1px horizontal line, `#dee2e6`

### Tracking Section

**Label:** "TRACKING" — Space Grotesk 10px bold, `#868e96`, uppercase, 1px letter-spacing

#### Loans
- **Sub-label:** "LOANS"
- Balances in red (negative)

#### Investments
- **Sub-label:** "INVESTMENTS"
- Balances in default color (positive)

### Net Worth
Below a second divider. Row with "Net Worth" label (Space Grotesk 12px semibold) and calculated value. Color reflects sign.

---

## Main Content Area

**Background:** `#FFFFFF`
**Layout:** Vertical — Account Header → Table Area → Legend Bar

### Account Header

**Padding:** 12px 16px
**Bottom border:** 1px `#dee2e6`
**Layout:** Horizontal, space-between

- **Left:** Account name (Space Grotesk 16px semibold) + account type label (Inter 12px, `#868e96`)
- **Right:** Balance summary — "Cleared: **$X**", "Uncleared: **$X**", "Balance: **$X**" (Inter 12px labels, Space Grotesk 12px semibold values) + "Reconcile" button (outlined, `#dee2e6` border, 4px radius)

### Transaction Table

**Density:** Compact (12px font, 3px vertical padding per cell)
**Fills remaining viewport height** with scrollable body and sticky header.

#### Table Header Row
- Background: `#f1f3f5`
- Bottom border: 1px `#dee2e6`
- Font: Space Grotesk 11px semibold, `#495057`, 0.5px letter-spacing

#### Columns

| Column | Width | Alignment |
|--------|-------|-----------|
| Status | 30px | Center |
| Date | 72px | Left |
| Payee | 3fr | Left |
| Category | 2fr | Left |
| Memo | 2fr | Left |
| Outflow | 85px | Right |
| Inflow | 85px | Right |
| Balance | 95px | Right |

Payee gets proportionally more space since payee names tend to be longer. Text in fill columns truncates with ellipsis on overflow.

#### Row Styles

- **Zebra striping:** Alternating rows use `#f8f9fa` background
- **Data font:** Inter 12px for text fields, Space Grotesk 12px for monetary values
- **Memo text:** `#868e96` (muted)
- **Outflow amounts:** `#c92a2a` (red)
- **Inflow amounts:** `#2b8a3e` (green)
- **Balance:** `#212529` (default)

#### Transaction Status Indicators

| Status | Visual | Description |
|--------|--------|-------------|
| Uncleared | Empty circle, 8px, 1.5px `#adb5bd` stroke | Not yet confirmed with bank |
| Cleared | Filled circle, 8px, `#51cf66` | Confirmed with bank |
| Reconciled | Filled circle, 8px, `#339af0` | Verified against statement |
| Scheduled | "S" label, dimmed row (50% opacity) | Future scheduled transaction |

#### Scheduled Transactions
- Appear at top of register
- Entire row at 50% opacity
- Background: `#fcfcfc`

### Legend Bar (pinned to bottom)

**Background:** `#FFFFFF`
**Top border:** 1px `#dee2e6`
**Padding:** 6px 16px
**Layout:** Horizontal, 16px gap

Shows status dot + label for each state: Uncleared, Cleared, Reconciled, Scheduled.

---

## Typography

| Element | Font | Size | Weight | Notes |
|---------|------|------|--------|-------|
| Brand name | Space Grotesk | 17px | 700 | |
| Brand tagline | Inter | 11px | 400 italic | |
| Nav items (inactive) | Space Grotesk | 13px | 500 | `#868e96` |
| Nav items (active) | Space Grotesk | 13px | 600 | White, blue underline |
| Budget status labels | Space Grotesk | 10px | 700, uppercase | ON-BUDGET / TRACKING |
| Account type labels | Space Grotesk | 10px | 600, uppercase | CASH / CREDIT / LOANS / INVESTMENTS |
| Account names | Inter | 12px | 400 | 500 when selected |
| Account balances | Space Grotesk | 12px | 400 | 600 when selected |
| Group totals | Space Grotesk | 11px | 400 | `#868e96` |
| Net Worth label | Space Grotesk | 12px | 600 | |
| Account heading | Space Grotesk | 16px | 600 | |
| Balance summary labels | Inter | 12px | 400 | "Cleared:", "Uncleared:", "Balance:" |
| Balance summary values | Space Grotesk | 12px | 600 | |
| Reconcile button | Space Grotesk | 12px | 500 | `#495057` |
| Table headers | Space Grotesk | 11px | 600 | 0.5px letter-spacing |
| Table text (payee, category) | Inter | 12px | 400 | |
| Table monetary values | Space Grotesk | 12px | 400 | |
| Table memo text | Inter | 12px | 400 | `#868e96` |
| + Transaction button | Space Grotesk | 11px | 600 | White on `#339af0` |
| Import link | Space Grotesk | 11px | 500 | `#868e96` |
| Legend labels | Inter | 11px | 400 | `#868e96` |

---

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Nav background | `#212529` | Top navigation bar |
| Sidebar background | `#f8f9fa` | Account sidebar |
| Content background | `#FFFFFF` | Main content area |
| Table header bg | `#f1f3f5` | Column header row |
| Zebra row | `#f8f9fa` | Alternating table rows |
| Selected account | `#e7f5ff` | Active account highlight |
| Border | `#dee2e6` | Dividers, borders |
| Primary text | `#212529` | Main text |
| Secondary text | `#868e96` | Labels, memos, muted |
| Tertiary text | `#495057` | Table headers, buttons |
| Accent blue | `#339af0` | Active nav, reconciled, CTA |
| Success green | `#51cf66` | Cleared status |
| Income green | `#2b8a3e` | Inflow amounts |
| Danger red | `#c92a2a` | Outflow amounts, negative balances |
| Muted | `#adb5bd` | Uncleared dots, scheduled text |
| Scheduled bg | `#fcfcfc` | Scheduled row background |

---

## Formatting Rules

- **Currency:** CAD. Format as `$1,234.56` with comma thousands separator and 2 decimal places.
- **Negative amounts:** Leading minus sign: `-$420.15`. No parenthetical notation.
- **Date format:** `MMM DD` in the table (e.g., "Mar 22"). 72px column width accommodates this format at 12px.
- **Transaction sort order:** Newest first (descending by date). Scheduled future transactions appear above all posted transactions.
- **Running balance:** Calculated top-down as displayed (newest at top). Balance = previous row's balance adjusted by the current row's inflow/outflow.
- **Net Worth:** Sum of all account balances (On-Budget + Tracking). Displayed in red if negative, `#2b8a3e` if positive.
- **Balance = Cleared + Uncleared** in the account header summary.

---

## Empty & Loading States

### No Transactions (empty account)
Table body shows a centered message: "No transactions yet" (Inter 14px, `#868e96`). Below it, a subtle prompt: "Click + Transaction to add your first one."

### No Accounts (first-time user)
Sidebar shows: "No accounts yet" (Inter 12px, `#868e96`). Main content area shows a centered onboarding prompt to add their first account.

### Loading State
When switching accounts, the table body shows a subtle skeleton: 6 rows of light gray (`#f1f3f5`) rectangular placeholders matching the column layout. The account header updates immediately with the new account name and balance.

---

## Interaction Notes (for implementation)

- Clicking an account in the sidebar loads its transactions in the main table (Turbo Frame or full page navigation — implementation decision)
- The "+ Transaction" button opens an inline form row at the top of the table body (above the first transaction)
- "Import" opens the bank import workflow (separate screen)
- "Reconcile" initiates the reconciliation flow for the selected account (separate screen)
- Table body scrolls independently; header stays sticky
- Sidebar scrolls independently if accounts overflow
- Hover states: sidebar account rows get `#e9ecef` background on hover; table rows get `#f1f3f5` background on hover; buttons follow Bootstrap defaults
- Negative running balances in the Balance column use red (`#c92a2a`)

---

## Out of Scope (deferred)

- Responsive / mobile layout
- Inline editing of transaction rows (will be designed separately)
- Transaction search, filtering, and column sorting
- Right-click context menus
- Bulk selection and bulk actions
- Drag-and-drop
- Transitions and animations
- Custom scrollbar styling (use browser defaults)
- Keyboard navigation and accessibility (will be addressed during implementation as a cross-cutting concern)
- Transfer transaction display conventions

## Sample Data

The design uses realistic Canadian financial data:
- **Cash:** Chequing ($3,147.70), Savings ($12,500.00)
- **Credit:** Visa (-$420.15)
- **Loans:** Mortgage (-$285,000)
- **Investments:** TFSA ($8,200.00), RRSP ($22,000.00)
- Transactions include: Loblaws, Tim Hortons, Shell, Costco, Netflix, Presto, Canadian Tire, Shoppers Drug Mart
