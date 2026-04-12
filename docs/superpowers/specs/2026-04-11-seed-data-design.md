# Seed Data Generation Design

**Date:** 2026-04-11
**Scope:** `db/seeds.rb` — programmatic generation of 5 years of realistic, fictional financial data for local dev/demo use.

---

## Goal

Replace the current minimal `db/seeds.rb` with a programmatic generator that produces ~5 years of realistic transaction history (2021-04-01 through 2026-03-31). Data is inspired by a real YNAB export but all payee names, amounts, and account names are fictional. No real personal information appears anywhere.

---

## Approach

Single `db/seeds.rb` file with:
- Static data tables (accounts, category taxonomy, payee pools) defined as Ruby constants at the top
- Helper methods for constructing TransactionEntries + TransactionLines
- A monthly generation loop with income drift and spending noise

No external gems. No extra files. Runs with `bin/rails db:seed`.

---

## Section 1: Ledger, User & Accounts

### Ledger
- Name: `"Demo Budget"`, currency: `"CAD"`

### User
- Email: `demo@example.com`, password: `password`
- Linked as `owner` via LedgerMembership

### User-facing Accounts

| Name | Type | On Budget |
|---|---|---|
| Northbrook Chequing | cash | yes |
| Northbrook Savings | cash | yes |
| Northbrook Credit Card | credit | yes |
| Summit Visa | credit | yes |
| Northbrook Mortgage | loan | no |
| Northbrook RRSP | investment | no |

### System Accounts (created automatically alongside categories)
- `Opening Balances` — equity
- `Income` — revenue
- One `expense`-type Account per category (same name), created when the Category is created

---

## Section 2: Category Taxonomy

Each category gets a backing `expense`-type Account with the same name.

| Group | Categories |
|---|---|
| Housing | Mortgage/Rent, Property Tax, Electricity, Natural Gas, Internet, Phone, House Insurance, Housekeeping |
| Food | Groceries, Restaurants, Alcohol |
| Transportation | Public Transit, Gas, Taxi |
| Personal | Pets, Software, Miscellaneous |
| Recreation | Night/Day Out, Entertainment |
| Savings | Emergency Fund, Retirement |
| Work | Expenses |

Income transactions credit the `revenue` Income account directly via transaction lines. No Inflow category is needed in the double-entry model.

---

## Section 3: Payees

All names are fictional. No real business names, personal names, or service names from the source data.

| Category | Payees |
|---|---|
| Income | Meridian Tech Inc., E-Transfer Received, Event Refund |
| Groceries | Green Valley Market, Harvest Bulk Foods, Cedar Farms, The Cheese Cellar |
| Restaurants | The Corner Diner, Sunrise Cafe, Spice Garden, Noodle House, The Pizza Co, QuickBite Delivery, Harbour Pub, Morning Brew, The Sandwich Board |
| Alcohol | The Bottle Shop, Fine Wine & Spirits |
| Public Transit | City Transit |
| Gas | Citywide Fuel |
| Taxi | RideShare |
| Internet | BrightNet |
| Phone | ClearConnect Mobile |
| House Insurance | Maple Shield Insurance |
| Housekeeping | CleanHome Services |
| Pets | Pawsome Pet Store, Litter & More |
| Software | StreamFlix, TuneCast, CloudDrive, Social Ads, PrimeMember |
| Miscellaneous | Government Services, The Pharmacy, Home Goods, Online Marketplace |
| Entertainment | The Spa, City Arena, Metro Art Gallery |
| Night/Day Out | Harbour Bar, The Lounge, Bistro de Ville |
| Work | Work Hotel, Airport Cafe, Conference Meals |

Transfers (mortgage payment, CC payments, RRSP contribution, Emergency Fund) use internal transfer entries with no payee.

---

## Section 4: Transaction Generation Strategy

### Date Range
2021-04-01 through 2026-03-31 (60 months). The loop iterates month by month.

### Income Drift
- Base: ~$5,500/month (semi-monthly: deposited on the 1st and 15th)
- Grows 2% per calendar year
- Entry type: `income`; lines: debit Northbrook Chequing (+), credit Income account (-)

### Spending Drift
- Each amount drawn from a base range, multiplied by `1 + (year_index * 0.015)` (1.5%/year cost-of-living)
- ±15% random noise applied per transaction
- December multiplier: 1.3× for Recreation (Night/Day Out, Entertainment) and Restaurants

### Status Assignment
- Transactions older than 60 days → `reconciled`
- 14–60 days old → `cleared`
- Within 14 days → `uncleared`

### Monthly Recurring Transactions

| Transaction | Account(s) | Type |
|---|---|---|
| 2× income deposits (1st, 15th) | → Chequing | income |
| Mortgage payment | Chequing → Mortgage | transfer |
| Northbrook CC payment | Chequing → Northbrook CC | transfer — amount ≈ prior month's CC spend |
| Summit Visa payment | Chequing → Summit Visa | transfer — amount ≈ prior month's CC spend |
| Internet (BrightNet) | Summit Visa | expense |
| Phone (ClearConnect Mobile) | Summit Visa | expense |
| House Insurance (Maple Shield) | Summit Visa | expense |
| Electricity | Chequing | expense — seasonal: 1.4× Nov–Feb |
| Natural Gas | Chequing | expense — seasonal: 1.6× Nov–Feb |
| Property Tax | Chequing | expense |
| Software subscriptions (5 services) | Summit Visa | expense |
| Housekeeping | Northbrook CC | expense |
| Emergency Fund transfer | Chequing → Savings | transfer |

### Variable Transactions (per month, randomized)

| Category | Account | Frequency |
|---|---|---|
| Groceries | Northbrook CC or Summit Visa | 4–5 trips |
| Restaurants | Northbrook CC or Summit Visa | 7–12 transactions |
| Alcohol | Northbrook CC | 1–3 transactions |
| Public Transit | Northbrook CC | 6–10 top-ups |
| Gas | Northbrook CC | 1–3 fill-ups |
| Taxi | Summit Visa | 0–3 rides |
| Pets | Summit Visa | 0–2 transactions |
| Miscellaneous | Northbrook CC or Summit Visa | 1–4 transactions |
| Entertainment | Summit Visa | 1–2 per month (higher Dec) |
| Night/Day Out | Northbrook CC | 1–3 per month (higher Dec) |
| Work Expenses | Northbrook CC | 0–3 per month (weekdays only) |

### Annual Transactions
- **RRSP contribution:** Once per year in February. Lump sum transfer Chequing → RRSP (amount ~$6,000, slight year-over-year growth).

---

## Double-Entry Structure

Each TransactionEntry has exactly two TransactionLines summing to zero:

| Entry type | Line 1 | Line 2 |
|---|---|---|
| Expense (cash) | expense account: +amount | chequing: −amount |
| Expense (credit) | expense account: +amount | credit card: −amount |
| Income | chequing: +amount | revenue account: −amount |
| Transfer | destination account: +amount | source account: −amount |

---

## Seed Execution

```
bin/rails db:seed
```

Clears all existing data first (destroys in dependency order). Prints progress as it goes. Expected runtime: ~10–30 seconds for 5 years of data.
