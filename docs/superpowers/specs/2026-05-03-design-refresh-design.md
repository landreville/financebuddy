# F-Buddy Design Refresh

## Overview

Refresh the existing F-Buddy UI from a clean/modern Bootstrap look to an old-web aesthetic with subtle cyberpunk touches. The design source is a Claude Design mockup (in `docs/design/mockup/`). The target stack remains Bootstrap 5 + Rails ERB templates + Dart Sass.

## Design Principles

- **Old web feel**: hard borders, no rounding, beveled/inset buttons, monospace everything
- **Subtle cyberpunk**: glitch on selected row, blinking caret in status bar
- **Bauhaus palette**: white / red / cobalt / black — small, deliberate
- **Ledger density**: compact rows, tabular numerals, lots of data per screen

## 1. Color Palette

Replace all `$fb-*` variables with CSS custom properties and a matching SCSS map.

| Token | Value | Usage |
|-------|-------|-------|
| `--paper` | `#FFFFFF` | Primary surface / background |
| `--paper-2` | `#F0F0F0` | Secondary surface (toolbar bg, zebra alt) |
| `--ink` | `#111111` | Primary text, borders, dark surfaces |
| `--ink-soft` | `#2A2A2A` | Dark surface borders, hover states |
| `--rule` | `#111111` | Borders (same as ink) |
| `--red` | `#C2272D` | Danger, outflow, primary button, brand accent |
| `--blue` | `#0046A8` | Links, inflow, cleared status, charts |
| `--white` | `#FFFFFF` | Text on dark surfaces |
| `--muted` | `#6B6B6B` | Secondary text, disabled states |

Bevel shadows:
- `--shadow-bevel-out`: `inset 1px 1px 0 #FFFFFF, inset -1px -1px 0 #999999`
- `--shadow-bevel-in`: `inset 1px 1px 0 #999999, inset -1px -1px 0 #FFFFFF`

## 2. Typography

- **Font**: JetBrains Mono (weights 400, 500, 700) — replaces Inter + Space Grotesk entirely
- **Size scale**: xs=11px, sm=12px, md=13px, lg=16px, xl=22px
- **Tabular numerals**: `font-feature-settings: "tnum" 1, "zero" 1`
- **Chrome/labels**: ALL-CAPS + `letter-spacing: 1-1.5px`
- **Content**: sentence case, no extra letter-spacing

## 3. Borders & Bevels

- Global override: `*, *::before, *::after { border-radius: 0 !important; }`
- All borders: `1px solid var(--ink)` — no exceptions
- Buttons: outset bevel by default, inset bevel on `:active` / `.is-active`
- Inputs: inset bevel by default; blue border + blue outline ring on `:focus`
- Primary button (`.btn--primary`): `background: var(--red); color: var(--white)`
- Ghost button (`.btn--ghost`): transparent bg, no bevel shadow

## 4. Layout Shell

Replace the current flex layout with CSS grid:

```
.app {
  display: grid;
  grid-template-rows: 44px 1fr 22px;
  height: 100vh;
}
```

- **Row 1 (44px)**: Header — dark `var(--ink)` background
- **Row 2 (1fr)**: Body — sidebar (280px) + main content
- **Row 3 (22px)**: Status bar — dark `var(--ink)` background (NEW)

## 5. Header

3-column grid: `280px 1fr 280px`

- **Left (brand)**: Red `F` square mark with blue offset shadow + "F-BUDDY" name + "F as in Finance" tagline
- **Center (nav)**: Flat button-style tabs with 1px `#2A2A2A` borders between items
  - Active state: `background: var(--paper); color: var(--ink)` + red 2px top line
  - Hover: `background: #1B1B1B`
- **Right (status)**: Green `#39FF14` "ONLINE" dot + live UTC clock

## 6. Sidebar (280px)

- Dark header bar: "ACCOUNTS" label + "＋ NEW" link
- Net worth section: "NET WORTH" label + large bold value
- Account groups: dark `var(--ink)` header with group name + total, collapsible chevron
- Account rows: dashed `#CCCCCC` bottom borders, hover = white bg
- Active account: `background: var(--ink); color: var(--white)` + red `►` caret
- Negative balances: red text; on active row: `#FF8B8B`

## 7. Accounts Page (hero screen)

**Account header:**
- Account name (xl size) + "// Working Balance · $X,XXX.XX" subtitle
- Balance row: bordered boxes for Cleared (blue value), Uncleared (red value), Working

**Toolbar:**
- Beveled buttons: "＋ ADD TXN" (primary red), "EDIT", "FILE ▾"
- Inset-beveled search input
- Spacer + row count meta + "⇩ EXPORT" / "⟳ RECONCILE" buttons

**Ledger table:**
- Sticky `<thead>`: `background: var(--ink); color: var(--white)`, uppercase letter-spaced headers
- Column widths: status 28px, date 100px, payee 22%, category 22%, memo auto, outflow 110px, inflow 110px
- Zebra: even rows `#F7F7F7`
- Hover: `#FFFBD6`
- Selected row: `background: var(--ink); color: var(--white)`, outflow = `#FF8B8B`, inflow = `#9CFFC4`
- Status pills: 16x16 bordered squares — cleared = blue bg, reconciled = black bg, uncleared = empty

## 8. Dashboard

- KPI row: 4 panel cards (dark header + white body + large number)
- 2-column grid: spending-by-category (progress bars) + net-worth sparkline (SVG)
- Recent activity table: dashed border rows, date + payee + category + amount

## 9. Budget

- Header: month name + "To Be Assigned" subtitle
- Balance boxes: Budgeted / Activity / Available
- Toolbar: month nav (‹ APR / MAY 2026 / JUN ›) + "＋ CATEGORY GROUP" / "ASSIGN MONEY" buttons
- Table: group sub-headers (grey bg + uppercase), per-row available column = progress bar + amount

## 10. Reports

- Header: "Reports" + subtitle + Income/Expense/Net balance boxes
- Toolbar: report type tabs (INCOME / EXPENSE, SPENDING TRENDS, NET WORTH, CASH FLOW)
- 2-column grid: monthly net bar chart (SVG) + expense mix stacked bar + legend
- Full-width: category detail table (months as columns)

## 11. Recurring

- Header + balance boxes: Inflow/mo, Outflow/mo, Net/mo
- Toolbar: filter tabs (ALL, BILLS, INCOME, SUBSCRIPTIONS) + "＋ NEW SCHEDULE"
- Table: status pill + name + account + frequency + next date + amount

## 12. Login Page

- Centered card: hard `1px solid var(--ink)` border, zero radius, no box-shadow
- Inset-beveled form inputs
- Red primary "Sign in" button with bevel
- Forgot password link: blue underline, hover = blue bg + white text

## 13. Cyberpunk Effects

**Blinking caret (status bar):**
- `_` character with `animation: caret 1s steps(1) infinite`
- `@keyframes caret { 50% { opacity: 0; } }`

**Glitch on selected row:**
- `@keyframes glitch-shift`: subtle 1px translate shifts at 93-97% of cycle, rest idle
- Applied to `.ledger tbody tr.is-selected` via class toggle
- Payee column gets RGB text-shadow split: `1px 0 0 var(--red), -1px 0 0 #00E5A8`

**No CRT scanlines overlay** (excluded per user preference).

## 14. Scrollbar Styling

- Track: `var(--paper-2)` with `border-left: 1px solid var(--ink)`
- Thumb: `var(--ink)` with `2px solid var(--paper-2)` border

## 15. Bootstrap Overrides

Since `_variables.scss` is currently imported *after* Bootstrap (making `!default` overrides impossible), we will:

1. Create `_bootstrap_overrides.scss` that sets Bootstrap `$enable-rounded: false` and other `!default` variables
2. Import it *before* `@import 'bootstrap/scss/bootstrap'` in `application.bootstrap.scss`
3. Keep custom design tokens as CSS custom properties in `:root` (the mockup's `--*` system)
4. Add global `border-radius: 0 !important` as a safety net

## 16. Files to Modify

| File | Change |
|------|--------|
| `app/assets/stylesheets/application.bootstrap.scss` | Restructure imports, add overrides |
| `app/assets/stylesheets/_variables.scss` | Replace `$fb-*` with CSS custom properties |
| `app/assets/stylesheets/_bootstrap_overrides.scss` | NEW — Bootstrap `!default` overrides |
| `app/assets/stylesheets/components/_top_nav.scss` | Rewrite as header grid |
| `app/assets/stylesheets/components/_sidebar.scss` | Rewrite with dark group headers |
| `app/assets/stylesheets/components/_transaction_table.scss` | Rewrite as ledger |
| `app/assets/stylesheets/components/_legend_bar.scss` | Remove (replaced by status bar) |
| `app/assets/stylesheets/components/_session.scss` | Apply new palette + bevels |
| `app/assets/stylesheets/components/_status_bar.scss` | NEW |
| `app/assets/stylesheets/components/_panels.scss` | NEW — panel/kpi/bar components |
| `app/assets/stylesheets/components/_buttons.scss` | NEW — bevel button system |
| `app/assets/stylesheets/components/_effects.scss` | NEW — glitch + caret animations |
| `app/views/layouts/application.html.erb` | New grid shell, font swap, status bar |
| `app/views/shared/_top_nav.html.erb` | Rewrite header markup |
| `app/views/shared/_sidebar.html.erb` | Rewrite sidebar markup |
| `app/views/shared/_status_bar.html.erb` | NEW |
| `app/views/accounts/show.html.erb` | Rewrite as ledger table |
| `app/views/dashboard/index.html.erb` | Rewrite with panels/KPIs |
| `app/views/budget/index.html.erb` | Rewrite with budget table |
| `app/views/reports/index.html.erb` | Rewrite with charts |
| `app/views/recurring_transactions/index.html.erb` | Rewrite with table |
| `app/views/sessions/new.html.erb` | Apply new palette |

## Scope Boundaries

- **In scope**: All visual changes described above, applied to existing Rails views
- **Out of scope**: New features, data model changes, JavaScript behavior changes (beyond Stimulus for row selection), the mockup's "Tweaks Panel" (design-tool artifact), CRT scanlines
- **Functional note**: The mockup's React interactivity (status toggle, search filtering) already exists or will be handled by existing Turbo/ Stimulus patterns — we are only refreshing the visual layer
