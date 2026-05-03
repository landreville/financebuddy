# Design Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the F-Buddy UI from modern Bootstrap to old-web + subtle cyberpunk aesthetic using JetBrains Mono, hard borders, beveled buttons, Bauhaus palette, glitch effects, and a status bar.

**Architecture:** Replace the existing `$fb-*` SCSS variable system with CSS custom properties matching the mockup's `:root` tokens. Restructure the layout from flex to CSS grid (header / body / status bar). Rewrite all component SCSS as BEM with the new palette. Rewrite all ERB templates to match the mockup's markup structure. Add glitch + caret CSS animations.

**Tech Stack:** Rails 8, Bootstrap 5.3 (heavily themed), Dart Sass, Hotwire (Turbo + Stimulus), JetBrains Mono (Google Fonts)

---

## File Structure

| File | Responsibility |
|------|---------------|
| `app/assets/stylesheets/_bootstrap_overrides.scss` | NEW — Bootstrap `!default` overrides (no rounding, font stack) |
| `app/assets/stylesheets/_variables.scss` | Rewrite — CSS custom properties replacing `$fb-*` SCSS vars |
| `app/assets/stylesheets/application.bootstrap.scss` | Restructure imports, add new component partials |
| `app/assets/stylesheets/components/_base.scss` | NEW — Global resets, html/body, links, scrollbar, type-swap |
| `app/assets/stylesheets/components/_buttons.scss` | NEW — Bevel button system (.btn, .btn--primary, .btn--ghost) |
| `app/assets/stylesheets/components/_panels.scss` | NEW — Panel, KPI, progress bar, sparkline/bar chart |
| `app/assets/stylesheets/components/_effects.scss` | NEW — Glitch animation, caret blink keyframes |
| `app/assets/stylesheets/components/_header.scss` | NEW — Replaces _top_nav.scss, 3-column grid header |
| `app/assets/stylesheets/components/_sidebar.scss` | Rewrite — Dark group headers, active caret, net worth |
| `app/assets/stylesheets/components/_ledger.scss` | NEW — Replaces _transaction_table.scss, proper `<table>` |
| `app/assets/stylesheets/components/_status_bar.scss` | NEW — Bottom status bar with blink |
| `app/assets/stylesheets/components/_session.scss` | Rewrite — New palette, bevels, hard borders |
| `app/assets/stylesheets/components/_top_nav.scss` | DELETE (replaced by _header.scss) |
| `app/assets/stylesheets/components/_transaction_table.scss` | DELETE (replaced by _ledger.scss) |
| `app/assets/stylesheets/components/_legend_bar.scss` | DELETE (replaced by _status_bar.scss) |
| `app/views/layouts/application.html.erb` | Rewrite — Grid shell, font, status bar |
| `app/views/shared/_top_nav.html.erb` | Rewrite — Header markup |
| `app/views/shared/_sidebar.html.erb` | Rewrite — Sidebar with group headers |
| `app/views/shared/_status_bar.html.erb` | NEW — Status bar partial |
| `app/views/accounts/show.html.erb` | Rewrite — Ledger table |
| `app/views/accounts/index.html.erb` | Rewrite — New markup |
| `app/views/dashboard/index.html.erb` | Rewrite — KPIs, panels, recent activity |
| `app/views/budget/index.html.erb` | Rewrite — Budget table with progress bars |
| `app/views/reports/index.html.erb` | Rewrite — Charts + category detail |
| `app/views/recurring_transactions/index.html.erb` | Rewrite — Recurring table |
| `app/views/sessions/new.html.erb` | Rewrite — New palette |
| `app/views/passwords/new.html.erb` | Rewrite — New palette |
| `app/views/passwords/edit.html.erb` | Rewrite — New palette |
| `app/views/home/index.html.erb` | Rewrite — Simple landing |
| `app/helpers/application_helper.rb` | Add `fmt_money` helper |

---

### Task 1: Create Branch + Bootstrap Overrides + CSS Variables

**Files:**
- Create: `app/assets/stylesheets/_bootstrap_overrides.scss`
- Modify: `app/assets/stylesheets/_variables.scss`
- Modify: `app/assets/stylesheets/application.bootstrap.scss`

- [ ] **Step 1: Create the feature branch**

```bash
git checkout -b design-refresh
```

- [ ] **Step 2: Create `_bootstrap_overrides.scss`**

```scss
$enable-rounded: false;
$font-family-base: "JetBrains Mono", ui-monospace, Menlo, Consolas, monospace;
$font-size-base: 13px;
$line-height-base: 1.35;
$border-radius: 0;
$border-radius-sm: 0;
$border-radius-lg: 0;
$primary: #C2272D;
$danger: #C2272D;
$info: #0046A8;
$body-bg: #FFFFFF;
$body-color: #111111;
$border-color: #111111;
```

- [ ] **Step 3: Rewrite `_variables.scss` with CSS custom properties**

Replace entire file with:

```scss
:root {
  --paper: #FFFFFF;
  --paper-2: #F0F0F0;
  --ink: #111111;
  --ink-soft: #2A2A2A;
  --rule: #111111;
  --red: #C2272D;
  --blue: #0046A8;
  --white: #FFFFFF;
  --muted: #6B6B6B;

  --shadow-bevel-out: inset 1px 1px 0 #FFFFFF, inset -1px -1px 0 #999999;
  --shadow-bevel-in: inset 1px 1px 0 #999999, inset -1px -1px 0 #FFFFFF;

  --mono: "JetBrains Mono", ui-monospace, Menlo, Consolas, monospace;
  --font: var(--mono);

  --fz-xs: 11px;
  --fz-sm: 12px;
  --fz-md: 13px;
  --fz-lg: 16px;
  --fz-xl: 22px;

  --row-h: 26px;
}
```

- [ ] **Step 4: Restructure `application.bootstrap.scss`**

Replace entire file with:

```scss
@import "bootstrap_overrides";
@import "bootstrap/scss/bootstrap";
@import "bootstrap-icons/font/bootstrap-icons";
@import "variables";
@import "components/base";
@import "components/buttons";
@import "components/effects";
@import "components/header";
@import "components/sidebar";
@import "components/ledger";
@import "components/status_bar";
@import "components/panels";
@import "components/session";
```

- [ ] **Step 5: Delete old component SCSS files that are being replaced**

```bash
rm app/assets/stylesheets/components/_top_nav.scss
rm app/assets/stylesheets/components/_transaction_table.scss
rm app/assets/stylesheets/components/_legend_bar.scss
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: restructure SCSS foundation with new palette and overrides"
```

---

### Task 2: Base Styles + Buttons + Effects

**Files:**
- Create: `app/assets/stylesheets/components/_base.scss`
- Create: `app/assets/stylesheets/components/_buttons.scss`
- Create: `app/assets/stylesheets/components/_effects.scss`

- [ ] **Step 1: Create `_base.scss`**

```scss
* { box-sizing: border-box; }

*, *::before, *::after { border-radius: 0 !important; }

html, body {
  margin: 0;
  padding: 0;
  background: var(--paper);
  color: var(--ink);
  font-family: var(--font);
  font-size: var(--fz-md);
  font-feature-settings: "tnum" 1, "zero" 1;
  line-height: 1.35;
  height: 100%;
  overflow: hidden;
}

button, input, select, textarea {
  font-family: inherit;
  font-size: inherit;
  color: inherit;
}

a {
  color: var(--blue);
  text-decoration: underline;
  text-underline-offset: 2px;
}

a:hover {
  background: var(--blue);
  color: var(--paper);
  text-decoration: none;
}

.app {
  display: grid;
  grid-template-rows: 44px 1fr 22px;
  height: 100vh;
  width: 100vw;
}

.body {
  display: grid;
  grid-template-columns: 280px 1fr;
  min-height: 0;
}

::-webkit-scrollbar { width: 12px; height: 12px; }
::-webkit-scrollbar-track { background: var(--paper-2); border-left: 1px solid var(--ink); }
::-webkit-scrollbar-thumb { background: var(--ink); border: 2px solid var(--paper-2); }
```

- [ ] **Step 2: Create `_buttons.scss`**

```scss
.btn {
  appearance: none;
  border: 1px solid var(--ink);
  background: var(--paper-2);
  color: var(--ink);
  padding: 3px 10px;
  height: 26px;
  cursor: pointer;
  text-transform: uppercase;
  letter-spacing: 1px;
  font-size: var(--fz-xs);
  box-shadow: var(--shadow-bevel-out);
  display: inline-flex;
  align-items: center;
  gap: 6px;
  text-decoration: none;

  &:hover {
    background: var(--white);
    color: var(--ink);
  }

  &:active, &.is-active {
    box-shadow: var(--shadow-bevel-in);
    background: var(--paper-2);
  }

  &--primary {
    background: var(--red);
    color: var(--paper);
    box-shadow: var(--shadow-bevel-out);

    &:hover {
      background: #A11D22;
      color: var(--paper);
    }

    &:active {
      box-shadow: var(--shadow-bevel-in);
    }
  }

  &--ghost {
    background: transparent;
    box-shadow: none;
    border-color: transparent;

    &:hover {
      background: transparent;
      text-decoration: underline;
    }
  }
}
```

- [ ] **Step 3: Create `_effects.scss`**

```scss
@keyframes caret {
  50% { opacity: 0; }
}

@keyframes glitch-shift {
  0%, 92%, 100% { transform: translate(0, 0); }
  93% { transform: translate(-1px, 0); }
  94% { transform: translate(1px, 0); }
  95% { transform: translate(0, -1px); }
  96% { transform: translate(-1px, 1px); }
  97% { transform: translate(0, 0); }
}

.ledger tbody tr.is-selected td {
  animation: glitch-shift 3.5s infinite;
}

.ledger tbody tr.is-selected td.col-payee {
  text-shadow: 1px 0 0 var(--red), -1px 0 0 #00E5A8;
}
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add base styles, bevel buttons, and glitch effects"
```

---

### Task 3: Header Component

**Files:**
- Create: `app/assets/stylesheets/components/_header.scss`
- Modify: `app/views/shared/_top_nav.html.erb`
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Create `_header.scss`**

```scss
.hdr {
  display: grid;
  grid-template-columns: 280px 1fr 280px;
  align-items: stretch;
  background: var(--ink);
  color: var(--paper);
  border-bottom: 1px solid var(--ink);

  &__brand {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 0 12px;
    border-right: 1px solid #333;
  }

  &__mark {
    width: 24px;
    height: 24px;
    display: grid;
    place-items: center;
    background: var(--red);
    color: var(--paper);
    font-weight: 700;
    letter-spacing: 0;
    font-size: 14px;
    position: relative;

    &::after {
      content: "";
      position: absolute;
      right: -3px;
      bottom: -3px;
      width: 24px;
      height: 24px;
      background: var(--blue);
      z-index: -1;
    }
  }

  &__name {
    font-weight: 700;
    letter-spacing: 0.5px;
  }

  &__tag {
    color: #B8B8B8;
    font-size: var(--fz-xs);
    margin-left: 4px;
  }

  &__nav {
    display: flex;
    align-items: stretch;
  }

  &__nav-link {
    background: transparent;
    color: var(--paper);
    border: 0;
    border-right: 1px solid #2A2A2A;
    padding: 0 16px;
    text-transform: uppercase;
    letter-spacing: 1px;
    font-size: var(--fz-sm);
    cursor: pointer;
    position: relative;
    display: flex;
    align-items: center;
    text-decoration: none;

    &:first-child {
      border-left: 1px solid #2A2A2A;
    }

    &:hover {
      background: #1B1B1B;
      color: #FFFFFF;
    }

    &.is-active {
      background: var(--paper);
      color: var(--ink);

      &::before {
        content: "";
        position: absolute;
        left: 0;
        right: 0;
        top: 0;
        height: 2px;
        background: var(--red);
      }
    }
  }

  &__right {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 10px;
    padding: 0 12px;
    border-left: 1px solid #333;
    font-size: var(--fz-xs);
    color: #B8B8B8;
  }

  &__dot {
    width: 8px;
    height: 8px;
    background: #39FF14;
    display: inline-block;
  }
}
```

- [ ] **Step 2: Rewrite `_top_nav.html.erb`**

Replace entire file with:

```erb
<header class="hdr">
  <div class="hdr__brand">
    <div class="hdr__mark">F</div>
    <div>
      <span class="hdr__name">F-BUDDY</span>
      <span class="hdr__tag">F as in Finance</span>
    </div>
  </div>
  <nav class="hdr__nav">
    <%= link_to "Dashboard", dashboard_path, class: "hdr__nav-link #{'is-active' if controller_name == 'dashboard'}" %>
    <%= link_to "Budget", budget_path, class: "hdr__nav-link #{'is-active' if controller_name == 'budget'}" %>
    <%= link_to "Accounts", accounts_path, class: "hdr__nav-link #{'is-active' if controller_name == 'accounts'}" %>
    <%= link_to "Reports", reports_path, class: "hdr__nav-link #{'is-active' if controller_name == 'reports'}" %>
    <%= link_to "Recurring", recurring_transactions_path, class: "hdr__nav-link #{'is-active' if controller_name == 'recurring_transactions'}" %>
  </nav>
  <div class="hdr__right">
    <span class="hdr__dot"></span> ONLINE
  </div>
</header>
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add header component with Bauhaus palette and nav"
```

---

### Task 4: Sidebar Component

**Files:**
- Rewrite: `app/assets/stylesheets/components/_sidebar.scss`
- Rewrite: `app/views/shared/_sidebar.html.erb`
- Modify: `app/helpers/application_helper.rb`

- [ ] **Step 1: Rewrite `_sidebar.scss`**

Replace entire file with:

```scss
.side {
  background: var(--paper-2);
  border-right: 1px solid var(--ink);
  display: flex;
  flex-direction: column;
  min-height: 0;

  &__head {
    padding: 8px 10px;
    border-bottom: 1px solid var(--ink);
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: var(--ink);
    color: var(--paper);
    text-transform: uppercase;
    font-size: var(--fz-xs);
    letter-spacing: 1.2px;
  }

  &__net {
    padding: 10px 12px;
    border-bottom: 1px solid var(--ink);
    background: var(--white);

    .lbl {
      text-transform: uppercase;
      font-size: var(--fz-xs);
      color: var(--muted);
      letter-spacing: 1px;
    }

    .val {
      font-size: 20px;
      font-weight: 700;
    }
  }

  &__scroll {
    overflow-y: auto;
    flex: 1;
    min-height: 0;
  }

  &__group {
    border-bottom: 1px solid var(--ink);

    h4 {
      margin: 0;
      padding: 6px 10px;
      background: var(--ink);
      color: var(--paper);
      text-transform: uppercase;
      font-size: var(--fz-xs);
      letter-spacing: 1.4px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-weight: 500;
      cursor: pointer;

      .chev { font-size: 10px; }
      .total { color: #B8B8B8; font-weight: 700; }
    }
  }

  &__acct {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 8px;
    padding: 5px 10px 5px 18px;
    cursor: pointer;
    border-bottom: 1px dashed #CCCCCC;
    align-items: baseline;
    position: relative;
    text-decoration: none;
    color: var(--ink);

    &:last-child { border-bottom: 0; }
    &:hover { background: var(--white); color: var(--ink); }

    &.is-active {
      background: var(--ink);
      color: var(--paper);

      &::before {
        content: "\25BA";
        position: absolute;
        left: 6px;
        top: 5px;
        font-size: 10px;
        color: var(--red);
      }
    }

    .name {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .bal {
      font-variant-numeric: tabular-nums;

      &.neg { color: var(--red); }
    }

    &.is-active .bal.neg { color: #FF8B8B; }
  }
}
```

- [ ] **Step 2: Add `fmt_money` helper to `application_helper.rb`**

Replace entire file with:

```ruby
module ApplicationHelper
  def fmt_money(n, sign: false, blank_zero: false)
    return "".html_safe if blank_zero && (!n || n.abs < 0.005)
    abs = number_to_currency(n.abs, unit: "", precision: 2)
    if sign
      prefix = n < 0 ? "-" : n > 0 ? "+" : " "
      "#{prefix}$#{abs}".html_safe
    else
      prefix = n < 0 ? "-" : ""
      "#{prefix}$#{abs}".html_safe
    end
  end
end
```

- [ ] **Step 3: Rewrite `_sidebar.html.erb`**

Replace entire file with:

```erb
<aside class="side">
  <div class="side__head">
    <span>Accounts</span>
    <span style="opacity: 0.6;">＋ NEW</span>
  </div>
  <div class="side__net">
    <div class="lbl">Net Worth</div>
    <div class="val"><%= fmt_money(sidebar_accounts.sum(&:balance)) %></div>
  </div>
  <div class="side__scroll">
    <% sidebar_accounts.group_by(&:account_type).each do |type, accounts| %>
      <div class="side__group">
        <h4>
          <span><span class="chev">▼</span> <%= type.titleize %></span>
          <span class="total"><%= fmt_money(accounts.sum(&:balance)) %></span>
        </h4>
        <% accounts.each do |acct| %>
          <%= link_to account_path(acct), class: "side__acct #{'is-active' if local_assigns[:current_account]&.id == acct.id}" do %>
            <span class="name"><%= acct.name %></span>
            <span class="bal <%= acct.balance < 0 ? 'neg' : '' %>">
              <%= fmt_money(acct.balance) %>
            </span>
          <% end %>
        <% end %>
      </div>
    <% end %>
  </div>
</aside>
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: rewrite sidebar with dark group headers and net worth"
```

---

### Task 5: Ledger + Main Pane Styles

**Files:**
- Create: `app/assets/stylesheets/components/_ledger.scss`

- [ ] **Step 1: Create `_ledger.scss`**

```scss
.main {
  background: var(--paper);
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;

  &__head {
    padding: 14px 18px 10px;
    border-bottom: 1px solid var(--ink);
    background: var(--paper);
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: end;
    gap: 12px;
  }

  &__title {
    margin: 0;
    font-size: var(--fz-xl);
    font-weight: 700;
    letter-spacing: 0;
    text-transform: none;
  }

  &__sub {
    font-size: var(--fz-xs);
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 1.5px;
    margin-top: 4px;
  }

  &__balrow {
    display: flex;
    gap: 18px;
    margin-top: 10px;
  }

  &__balcell {
    border: 1px solid var(--ink);
    background: var(--white);
    padding: 6px 10px;
    min-width: 130px;

    .lbl {
      font-size: var(--fz-xs);
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 1.2px;
    }

    .val {
      font-size: 16px;
      font-weight: 700;
      font-variant-numeric: tabular-nums;
    }

    &.cleared .val { color: var(--blue); }
    &.uncleared .val { color: var(--red); }
  }
}

.tb {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border-bottom: 1px solid var(--ink);
  background: var(--paper-2);

  input[type="text"] {
    border: 1px solid var(--ink);
    background: var(--white);
    padding: 4px 8px;
    height: 26px;
    width: 240px;
    box-shadow: var(--shadow-bevel-in);

    &:focus {
      outline: 0;
      border-color: var(--blue);
      box-shadow: var(--shadow-bevel-in), 0 0 0 1px var(--blue);
    }
  }

  .spacer { flex: 1; }

  .meta {
    font-size: var(--fz-xs);
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 1px;
  }
}

.ledger {
  flex: 1;
  overflow: auto;
  border-top: 0;
  background: var(--white);

  table {
    width: 100%;
    border-collapse: collapse;
    font-size: var(--fz-md);
  }

  thead th {
    position: sticky;
    top: 0;
    z-index: 2;
    background: var(--ink);
    color: var(--paper);
    text-align: left;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 1.2px;
    font-size: var(--fz-xs);
    padding: 6px 8px;
    border-right: 1px solid #333;
    border-bottom: 1px solid var(--ink);
    white-space: nowrap;

    &:last-child { border-right: 0; }
  }

  tbody td {
    padding: 4px 8px;
    border-bottom: 1px solid #DDDDDD;
    border-right: 1px solid #EEEEEE;
    vertical-align: middle;
    height: var(--row-h);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;

    &:last-child { border-right: 0; }
  }

  tbody tr:nth-child(even) td { background: #F7F7F7; }
  tbody tr:hover td { background: #FFFBD6; }

  tbody tr.is-selected td {
    background: var(--ink) !important;
    color: var(--paper);
    position: relative;
  }

  tbody tr.is-selected td.col-out { color: #FF8B8B; }
  tbody tr.is-selected td.col-in { color: #9CFFC4; }

  .col-status { width: 28px; text-align: center; }
  .col-date { width: 100px; }
  .col-payee { width: 22%; }
  .col-cat { width: 22%; color: var(--blue); }
  .col-memo { width: auto; color: var(--muted); }

  .col-out, .col-in {
    width: 110px;
    text-align: right;
    font-variant-numeric: tabular-nums;
  }

  .col-out.has { color: var(--red); }
  .col-in.has { color: var(--blue); }
}

.st {
  display: inline-grid;
  place-items: center;
  width: 16px;
  height: 16px;
  border: 1px solid var(--ink);
  font-size: 10px;
  background: var(--white);
  cursor: pointer;

  &.cleared { background: var(--blue); color: var(--paper); }
  &.recon { background: var(--ink); color: var(--paper); }
  &:hover { box-shadow: 0 0 0 1px var(--red); }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add ledger table and main pane styles"
```

---

### Task 6: Status Bar + Panels

**Files:**
- Create: `app/assets/stylesheets/components/_status_bar.scss`
- Create: `app/assets/stylesheets/components/_panels.scss`

- [ ] **Step 1: Create `_status_bar.scss`**

```scss
.statusbar {
  display: grid;
  grid-template-columns: auto 1fr auto auto auto;
  gap: 0;
  background: var(--ink);
  color: var(--paper);
  font-size: var(--fz-xs);
  letter-spacing: 1px;
  text-transform: uppercase;

  > * {
    padding: 3px 10px;
    border-right: 1px solid #333;
    display: flex;
    align-items: center;
    gap: 6px;

    &:last-child { border-right: 0; }
  }

  .blink::after {
    content: "_";
    animation: caret 1s steps(1) infinite;
    margin-left: 2px;
  }
}
```

- [ ] **Step 2: Create `_panels.scss`**

```scss
.panel {
  border: 1px solid var(--ink);
  background: var(--white);
  margin: 0;

  &__h {
    padding: 6px 10px;
    background: var(--ink);
    color: var(--paper);
    text-transform: uppercase;
    letter-spacing: 1.2px;
    font-size: var(--fz-xs);
    border-bottom: 1px solid var(--ink);
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  &__b { padding: 12px; }
}

.kpi {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  gap: 10px;
  padding: 12px;

  .panel { padding: 0; }

  .v {
    font-size: 28px;
    font-weight: 700;
    padding: 8px 12px;
    font-variant-numeric: tabular-nums;
  }

  .l {
    font-size: var(--fz-xs);
    padding: 6px 12px;
    background: var(--ink);
    color: var(--paper);
    text-transform: uppercase;
    letter-spacing: 1.2px;
  }
}

.bar {
  height: 12px;
  background: var(--paper-2);
  border: 1px solid var(--ink);
  position: relative;
  overflow: hidden;

  > span {
    display: block;
    height: 100%;
    background: var(--blue);
  }

  &.over > span { background: var(--red); }
}
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add status bar and panel/kpi/bar styles"
```

---

### Task 7: Session (Login) Styles

**Files:**
- Rewrite: `app/assets/stylesheets/components/_session.scss`

- [ ] **Step 1: Rewrite `_session.scss`**

Replace entire file with:

```scss
.fb-login-card {
  width: 100%;
  max-width: 400px;
  padding: 2.5rem;
  background: var(--white);
  border: 1px solid var(--ink);

  &__title {
    font-size: var(--fz-xl);
    font-weight: 700;
    color: var(--ink);
    margin-bottom: 1.5rem;
    text-transform: uppercase;
    letter-spacing: 1px;
  }

  &__form {
    .form-label {
      font-size: var(--fz-xs);
      font-weight: 500;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .form-control {
      border: 1px solid var(--ink);
      font-size: var(--fz-md);
      box-shadow: var(--shadow-bevel-in);

      &:focus {
        border-color: var(--blue);
        box-shadow: var(--shadow-bevel-in), 0 0 0 1px var(--blue);
        outline: 0;
      }
    }
  }

  &__forgot {
    font-size: var(--fz-xs);
    color: var(--blue);
    text-decoration: underline;
    text-underline-offset: 2px;

    &:hover {
      background: var(--blue);
      color: var(--paper);
      text-decoration: none;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite session styles with new palette and bevels"
```

---

### Task 8: Layout + Status Bar Partial

**Files:**
- Rewrite: `app/views/layouts/application.html.erb`
- Create: `app/views/shared/_status_bar.html.erb`

- [ ] **Step 1: Rewrite `application.html.erb`**

Replace entire file with:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "F-Buddy" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= yield :head %>
    <link rel="icon" href="/icon.png" type="image/png">
    <link rel="icon" href="/icon.svg" type="image/svg+xml">
    <link rel="apple-touch-icon" href="/icon.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <div class="app">
      <%= render "shared/top_nav" %>
      <div class="body">
        <%= yield %>
      </div>
      <%= render "shared/status_bar" %>
    </div>
  </body>
</html>
```

- [ ] **Step 2: Create `_status_bar.html.erb`**

```erb
<div class="statusbar">
  <span>● READY</span>
  <span class="blink">SCREEN: <%= controller_name.upcase %></span>
  <span>SYNC: <%= Time.current.strftime("%d %b %Y %H:%M") %></span>
  <span>v0.4.2-cyber</span>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: rewrite layout with grid shell and status bar"
```

---

### Task 9: Accounts Show (Ledger)

**Files:**
- Rewrite: `app/views/accounts/show.html.erb`

- [ ] **Step 1: Rewrite `accounts/show.html.erb`**

Replace entire file with:

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
      <tbody>
        <% @transactions.each do |txn| %>
          <% line = txn.transaction_lines.find { |l| l.account_id == @account.id } %>
          <% next unless line %>
          <tr data-txn-id="<%= txn.id %>">
            <td class="col-status">
              <span class="st <%= txn.status == 'cleared' ? 'cleared' : (txn.status == 'reconciled' ? 'recon' : '') %>">
                <%= txn.status == 'cleared' ? 'C' : (txn.status == 'reconciled' ? 'R' : '·') %>
              </span>
            </td>
            <td class="col-date"><%= txn.date.strftime("%y-%m-%d") %></td>
            <td class="col-payee"><%= txn.payee&.name || txn.entry_type.titleize %></td>
            <td class="col-cat"><%= txn.category&.name || "—" %></td>
            <td class="col-memo"><%= txn.memo %></td>
            <% if line.amount < 0 %>
              <td class="col-out has"><%= fmt_money(line.amount.abs) %></td>
              <td class="col-in"></td>
            <% else %>
              <td class="col-out"></td>
              <td class="col-in has"><%= fmt_money(line.amount) %></td>
            <% end %>
          </tr>
        <% end %>
        <% if @transactions.empty? %>
          <tr>
            <td colspan="7" style="padding: 24px; text-align: center; color: var(--muted);">
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
git add -A
git commit -m "feat: rewrite accounts show as ledger table"
```

---

### Task 10: Accounts Index

**Files:**
- Rewrite: `app/views/accounts/index.html.erb`

- [ ] **Step 1: Rewrite `accounts/index.html.erb`**

Replace entire file with:

```erb
<%= render "shared/sidebar", sidebar_accounts: @sidebar_accounts %>

<div class="main">
  <div class="main__head">
    <div>
      <h1 class="main__title">Accounts</h1>
      <div class="main__sub">// Select an account to view transactions</div>
    </div>
  </div>
  <div style="display: flex; align-items: center; justify-content: center; flex: 1; color: var(--muted); text-transform: uppercase; letter-spacing: 2px; font-size: var(--fz-sm);">
    — Select an account from the sidebar —
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite accounts index"
```

---

### Task 11: Dashboard

**Files:**
- Rewrite: `app/views/dashboard/index.html.erb`

- [ ] **Step 1: Rewrite `dashboard/index.html.erb`**

Replace entire file with:

```erb
<div class="main" style="overflow: auto;">
  <div class="main__head">
    <div>
      <h1 class="main__title">Dashboard</h1>
      <div class="main__sub">// Snapshot · <%= Date.today.strftime("%d %b %Y") %></div>
    </div>
  </div>

  <div class="kpi">
    <% @accounts.group_by(&:account_type).each do |type, accounts| %>
      <div class="panel">
        <div class="l"><%= type.titleize %></div>
        <div class="v" style="color: <%= accounts.sum(&:balance) < 0 ? 'var(--red)' : 'var(--ink)' %>">
          <%= fmt_money(accounts.sum(&:balance)) %>
        </div>
      </div>
    <% end %>
    <div class="panel">
      <div class="l">Net Worth</div>
      <div class="v" style="color: <%= @net_worth < 0 ? 'var(--red)' : 'var(--ink)' %>">
        <%= fmt_money(@net_worth) %>
      </div>
    </div>
  </div>

  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; padding: 0 12px 12px;">
    <div class="panel">
      <div class="panel__h">
        <span>Spending / 30 Days</span>
        <span>By Category</span>
      </div>
      <div class="panel__b">
        <% spending_data = @accounts.flat_map { |a| a.transaction_entries.where("amount < 0") }.group_by { |t| t.category&.name || "Other" } %>
        <% if spending_data.any? %>
          <% spending_data.sort_by { |_, txns| -txns.sum(&:amount).abs }.first(6).each do |cat, txns| %>
            <div style="display: grid; grid-template-columns: 130px 1fr 80px; gap: 10px; align-items: center; margin-bottom: 8px;">
              <div style="font-size: var(--fz-sm)"><%= cat %></div>
              <div class="bar"><span style="width: 100%"></span></div>
              <div style="font-size: var(--fz-sm); text-align: right; font-variant-numeric: tabular-nums">
                <%= fmt_money(txns.sum(&:amount).abs) %>
              </div>
            </div>
          <% end %>
        <% else %>
          <div style="color: var(--muted); text-align: center; padding: 24px;">— No spending data —</div>
        <% end %>
      </div>
    </div>

    <div class="panel">
      <div class="panel__h">
        <span>Recent Activity</span>
        <span>Last 10</span>
      </div>
      <div style="padding: 0;">
        <table style="width: 100%; border-collapse: collapse; font-size: var(--fz-md);">
          <tbody>
            <% @recent_transactions.each do |txn| %>
              <tr style="border-bottom: 1px dashed #DDDDDD;">
                <td style="padding: 5px 10px; width: 90px; color: var(--muted)"><%= txn.date.strftime("%y-%m-%d") %></td>
                <td style="padding: 5px 10px"><%= txn.payee&.name || "—" %></td>
                <td style="padding: 5px 10px; color: var(--blue)"><%= txn.entry_type.titleize %></td>
                <td style="padding: 5px 10px; text-align: right; font-variant-numeric: tabular-nums; color: var(--muted)">
                  <%= txn.memo %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite dashboard with KPI panels and recent activity"
```

---

### Task 12: Budget

**Files:**
- Rewrite: `app/views/budget/index.html.erb`

- [ ] **Step 1: Rewrite `budget/index.html.erb`**

Replace entire file with:

```erb
<div class="main" style="overflow: auto;">
  <div class="main__head">
    <div>
      <h1 class="main__title">Budget · <%= @month.strftime("%B %Y") %></h1>
      <div class="main__sub">// To Be Assigned · <%= fmt_money(0) %></div>
    </div>
    <div class="main__balrow">
      <div class="main__balcell">
        <div class="lbl">Budgeted</div>
        <div class="val"><%= fmt_money(@category_groups.flat_map { |g| g.categories.where(archived: false) }.sum { |c| @allocations[c.id] || 0 }) %></div>
      </div>
      <div class="main__balcell uncleared">
        <div class="lbl">Activity</div>
        <div class="val"><%= fmt_money(-@category_groups.flat_map { |g| g.categories.where(archived: false) }.sum { |c| @activity[c.id] || 0 }) %></div>
      </div>
      <div class="main__balcell cleared">
        <div class="lbl">Available</div>
        <div class="val"><%= fmt_money(@category_groups.flat_map { |g| g.categories.where(archived: false) }.sum { |c| (@allocations[c.id] || 0) - (@activity[c.id] || 0) }) %></div>
      </div>
    </div>
  </div>

  <div class="tb">
    <%= link_to "‹ APR", budget_path(month: (@month << 1).to_s), class: "btn" %>
    <button class="btn is-active"><%= @month.strftime("%b %Y").upcase %></button>
    <%= link_to "JUN ›", budget_path(month: (@month >> 1).to_s), class: "btn" %>
    <div class="spacer"></div>
    <button class="btn">＋ CATEGORY GROUP</button>
    <button class="btn btn--primary">ASSIGN MONEY</button>
  </div>

  <div class="ledger">
    <table>
      <colgroup>
        <col style="width: 38%">
        <col style="width: 20%">
        <col style="width: 20%">
        <col style="width: 22%">
      </colgroup>
      <thead>
        <tr>
          <th>Category</th>
          <th style="text-align: right">Budgeted</th>
          <th style="text-align: right">Activity</th>
          <th>Available</th>
        </tr>
      </thead>
      <tbody>
        <% @category_groups.each do |group| %>
          <tr>
            <td colspan="4" style="background: var(--paper-2); text-transform: uppercase; letter-spacing: 1.5px; font-size: var(--fz-xs); padding: 6px 10px; border-top: 1px solid var(--ink); border-bottom: 1px solid var(--ink); font-weight: 700;">
              ▼ <%= group.name %>
            </td>
          </tr>
          <% group.categories.where(archived: false).order(:display_order, :name).each do |cat| %>
            <% assigned = @allocations[cat.id] || 0 %>
            <% activity = @activity[cat.id] || 0 %>
            <% available = assigned - activity %>
            <% pct = assigned > 0 ? [100, (activity.to_f / assigned * 100).round].min : 0 %>
            <% over = activity > assigned %>
            <tr>
              <td><%= cat.name %></td>
              <td style="text-align: right; font-variant-numeric: tabular-nums"><%= fmt_money(assigned) %></td>
              <td style="text-align: right; font-variant-numeric: tabular-nums; color: <%= activity > 0 ? 'var(--red)' : 'var(--muted)' %>">
                <%= activity > 0 ? "-#{fmt_money(activity)}" : "—" %>
              </td>
              <td>
                <div style="display: grid; grid-template-columns: 1fr 80px; gap: 8px; align-items: center;">
                  <div class="bar <%= over ? 'over' : '' %>"><span style="width: <%= pct %>%"></span></div>
                  <span style="text-align: right; font-variant-numeric: tabular-nums; color: <%= available < 0 ? 'var(--red)' : 'var(--blue)' %>; font-weight: 700">
                    <%= fmt_money(available) %>
                  </span>
                </div>
              </td>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite budget page with progress bars and bevel buttons"
```

---

### Task 13: Reports

**Files:**
- Rewrite: `app/views/reports/index.html.erb`

- [ ] **Step 1: Rewrite `reports/index.html.erb`**

Replace entire file with:

```erb
<div class="main" style="overflow: auto;">
  <div class="main__head">
    <div>
      <h1 class="main__title">Reports</h1>
      <div class="main__sub">// Income / Expense · <%= @month.strftime("%b %Y") %></div>
    </div>
  </div>

  <div class="tb">
    <button class="btn is-active">SPENDING</button>
    <div class="spacer"></div>
    <%= link_to "‹ PREV", reports_path(month: (@month << 1).to_s), class: "btn" %>
    <span class="meta"><%= @month.strftime("%b %Y").upcase %></span>
    <%= link_to "NEXT ›", reports_path(month: (@month >> 1).to_s), class: "btn" %>
  </div>

  <div style="padding: 12px;">
    <div class="panel">
      <div class="panel__h">
        <span>Spending by Category</span>
        <span><%= @month.strftime("%b %Y").upcase %></span>
      </div>
      <table style="width: 100%; border-collapse: collapse; font-size: var(--fz-md);">
        <thead>
          <tr style="background: var(--paper-2); border-bottom: 1px solid var(--ink);">
            <th style="text-align: left; padding: 6px 10px; text-transform: uppercase; letter-spacing: 1px; font-size: var(--fz-xs); font-weight: 500;">Group</th>
            <th style="text-align: left; padding: 6px 10px; text-transform: uppercase; letter-spacing: 1px; font-size: var(--fz-xs); font-weight: 500;">Category</th>
            <th style="text-align: right; padding: 6px 10px; text-transform: uppercase; letter-spacing: 1px; font-size: var(--fz-xs); font-weight: 500;">Amount</th>
            <th style="text-align: right; padding: 6px 10px; text-transform: uppercase; letter-spacing: 1px; font-size: var(--fz-xs); font-weight: 500; width: 120px;">% of Total</th>
          </tr>
        </thead>
        <tbody>
          <% @spending_by_category.each do |(group_name, cat_name), amount| %>
            <% pct = @total_spending > 0 ? (amount / @total_spending * 100).round(1) : 0 %>
            <tr style="border-bottom: 1px dashed #DDDDDD;">
              <td style="padding: 5px 10px; color: var(--muted)"><%= group_name %></td>
              <td style="padding: 5px 10px"><%= cat_name %></td>
              <td style="padding: 5px 10px; text-align: right; font-variant-numeric: tabular-nums; color: var(--red)">
                <%= fmt_money(amount) %>
              </td>
              <td style="padding: 5px 10px; text-align: right; font-variant-numeric: tabular-nums; color: var(--muted); width: 120px">
                <%= pct %>%
                <div class="bar" style="display: inline-block; width: 40px; height: 6px; vertical-align: middle; margin-left: 6px;">
                  <span style="width: <%= pct %>%"></span>
                </div>
              </td>
            </tr>
          <% end %>
          <% if @spending_by_category.empty? %>
            <tr>
              <td colspan="4" style="padding: 24px; text-align: center; color: var(--muted);">— No spending data for this month —</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite reports page with panels and styled table"
```

---

### Task 14: Recurring Transactions

**Files:**
- Rewrite: `app/views/recurring_transactions/index.html.erb`

- [ ] **Step 1: Rewrite `recurring_transactions/index.html.erb`**

Replace entire file with:

```erb
<div class="main" style="overflow: auto;">
  <div class="main__head">
    <div>
      <h1 class="main__title">Recurring</h1>
      <div class="main__sub">// Scheduled · Auto-detected from history</div>
    </div>
  </div>

  <div class="tb">
    <button class="btn is-active">ALL</button>
    <button class="btn">BILLS</button>
    <button class="btn">INCOME</button>
    <button class="btn">SUBSCRIPTIONS</button>
    <div class="spacer"></div>
    <button class="btn">＋ NEW SCHEDULE</button>
  </div>

  <div class="ledger">
    <table>
      <thead>
        <tr>
          <th style="width: 30px">✓</th>
          <th>Name</th>
          <th>Account</th>
          <th>Frequency</th>
          <th>Next Due</th>
          <th style="text-align: right">Amount</th>
        </tr>
      </thead>
      <tbody>
        <% @recurring.each do |rec| %>
          <% overdue = rec.next_due_date < Date.today %>
          <tr>
            <td><span class="st cleared">✓</span></td>
            <td><%= rec.payee&.name || "—" %></td>
            <td style="color: var(--blue)"><%= rec.account.name %></td>
            <td style="color: var(--muted); letter-spacing: 1px; font-size: var(--fz-xs)"><%= rec.frequency.titleize %></td>
            <td style="font-variant-numeric: tabular-nums; <%= overdue ? 'color: var(--red); font-weight: 700' : '' %>">
              <%= rec.next_due_date.strftime("%Y-%m-%d") %>
            </td>
            <td style="text-align: right; font-variant-numeric: tabular-nums; color: <%= rec.amount < 0 ? 'var(--red)' : 'var(--blue)' %>; font-weight: 700">
              <%= fmt_money(rec.amount, sign: true) %>
            </td>
          </tr>
        <% end %>
        <% if @recurring.empty? %>
          <tr>
            <td colspan="6" style="padding: 24px; text-align: center; color: var(--muted);">
              — No recurring transactions —
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
git add -A
git commit -m "feat: rewrite recurring transactions page with ledger table"
```

---

### Task 15: Login + Password Pages

**Files:**
- Rewrite: `app/views/sessions/new.html.erb`
- Rewrite: `app/views/passwords/new.html.erb`
- Rewrite: `app/views/passwords/edit.html.erb`

- [ ] **Step 1: Rewrite `sessions/new.html.erb`**

Replace entire file with:

```erb
<div class="d-flex justify-content-center align-items-center w-100">
  <div class="fb-login-card">
    <h1 class="fb-login-card__title">Sign In</h1>
    <% if flash[:alert] %>
      <div class="alert alert-danger py-2" style="border: 1px solid var(--red); font-size: var(--fz-sm)"><%= flash[:alert] %></div>
    <% end %>
    <% if flash[:notice] %>
      <div class="alert alert-success py-2" style="border: 1px solid var(--blue); font-size: var(--fz-sm)"><%= flash[:notice] %></div>
    <% end %>
    <%= form_with url: session_path, class: "fb-login-card__form" do |form| %>
      <div class="mb-3">
        <%= form.label :email_address, "Email", class: "form-label" %>
        <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "username", placeholder: "you@example.com", value: params[:email_address], class: "form-control" %>
      </div>
      <div class="mb-3">
        <div class="d-flex justify-content-between align-items-baseline">
          <%= form.label :password, "Password", class: "form-label mb-0" %>
          <%= link_to "Forgot password?", new_password_path, class: "fb-login-card__forgot" %>
        </div>
        <%= form.password_field :password, required: true, autocomplete: "current-password", placeholder: "••••••••", maxlength: 72, class: "form-control" %>
      </div>
      <%= form.submit "Sign in", class: "btn btn--primary w-100" %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 2: Rewrite `passwords/new.html.erb`**

Replace entire file with:

```erb
<div class="d-flex justify-content-center align-items-center w-100">
  <div class="fb-login-card">
    <h1 class="fb-login-card__title">Reset Password</h1>
    <%= tag.div(flash[:alert], style: "color: var(--red); font-size: var(--fz-sm); margin-bottom: 1rem;") if flash[:alert] %>
    <%= form_with url: passwords_path, class: "fb-login-card__form" do |form| %>
      <div class="mb-3">
        <%= form.label :email_address, "Email", class: "form-label" %>
        <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "username", placeholder: "Enter your email address", value: params[:email_address], class: "form-control" %>
      </div>
      <%= form.submit "Email reset instructions", class: "btn btn--primary w-100" %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 3: Rewrite `passwords/edit.html.erb`**

Replace entire file with:

```erb
<div class="d-flex justify-content-center align-items-center w-100">
  <div class="fb-login-card">
    <h1 class="fb-login-card__title">Update Password</h1>
    <%= tag.div(flash[:alert], style: "color: var(--red); font-size: var(--fz-sm); margin-bottom: 1rem;") if flash[:alert] %>
    <%= form_with url: password_path(params[:token]), method: :put, class: "fb-login-card__form" do |form| %>
      <div class="mb-3">
        <%= form.label :password, "New password", class: "form-label" %>
        <%= form.password_field :password, required: true, autocomplete: "new-password", placeholder: "Enter new password", maxlength: 72, class: "form-control" %>
      </div>
      <div class="mb-3">
        <%= form.label :password_confirmation, "Confirm password", class: "form-label" %>
        <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password", placeholder: "Repeat new password", maxlength: 72, class: "form-control" %>
      </div>
      <%= form.submit "Save", class: "btn btn--primary w-100" %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: rewrite login and password pages with new palette"
```

---

### Task 16: Home Page

**Files:**
- Rewrite: `app/views/home/index.html.erb`

- [ ] **Step 1: Rewrite `home/index.html.erb`**

Replace entire file with:

```erb
<div class="main" style="overflow: auto;">
  <div class="main__head">
    <div>
      <h1 class="main__title">Welcome</h1>
      <div class="main__sub">// F-Buddy · Personal Finance</div>
    </div>
  </div>
  <div style="display: flex; align-items: center; justify-content: center; flex: 1; color: var(--muted); text-transform: uppercase; letter-spacing: 2px; font-size: var(--fz-sm);">
    — Select a section from the navigation above —
  </div>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: rewrite home page with new design"
```

---

### Task 17: Build CSS + Verify

**Files:** None (verification only)

- [ ] **Step 1: Build the CSS**

```bash
yarn build:css
```

- [ ] **Step 2: Run linting**

```bash
srt -- bin/rubocop
```

- [ ] **Step 3: Run tests**

```bash
srt -- bin/rails test
```

- [ ] **Step 4: Fix any lint or test failures, then commit if needed**

```bash
git add -A && git commit -m "fix: resolve lint/test issues from design refresh"
```

---

### Task 18: Visual Verification in Browser

**Files:** None (manual check)

- [ ] **Step 1: Start the dev server**

```bash
bin/dev
```

- [ ] **Step 2: Verify each page visually**

Open a browser and check:
1. `/dashboard` — KPI cards, panels, dark headers, monospace font, hard borders
2. `/budget` — Progress bars, budget table, bevel buttons
3. `/accounts/1` — Ledger table, sticky dark thead, zebra striping, yellow hover, status pills, sidebar with dark group headers
4. `/reports` — Styled table with progress bars
5. `/recurring` — Recurring table with frequency/amount columns
6. `/session/new` — Login card with hard borders, beveled inputs, red primary button
7. Status bar at bottom — dark bar with blinking caret
8. Header — dark bar with red F mark, blue offset, active nav with red top line

- [ ] **Step 3: Fix any visual issues found and commit**

```bash
git add -A && git commit -m "fix: visual adjustments from browser review"
```
