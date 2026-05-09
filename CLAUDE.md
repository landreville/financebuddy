# FinanceBuddy

Personal finance / budgeting app. Rails 8, PostgreSQL (pgvector), Hotwire.

## Development

```bash
docker compose up -d          # postgres + redis
bin/rails db:prepare           # create/migrate database
bin/rails test                 # run tests (minitest)
bin/rubocop                    # lint (standardrb)
bin/dev                        # start app (foreman: rails server + css watch)
```

## Architecture

- **Double-entry bookkeeping**: Every transaction has transaction_lines that must sum to zero. Debits are positive, credits are negative.
- **TransactionEntry** uses `self.table_name = "transactions"` to avoid the reserved word `transaction` as a model name.
- **Enums are strings**, not integers (e.g. `account_type`, `entry_type`, `status`). Validated with `inclusion: {in: CONSTANT}`.
- **All data is ledger-scoped**: accounts, categories, payees, transactions all belong to a ledger. Users access ledgers via ledger_memberships. Any user that should see app data needs a `LedgerMembership` — `ApplicationController#set_current_ledger` redirects to root if `Current.user.ledgers.first` is nil. Whenever you add a code path that creates users (e.g. signup), create a LedgerMembership in the same step.

## Authentication

- Session lookup cookie is `:financebuddy_session_id` (signed). Do **not** rename it to `:session_id` — that name conflicts with something in the Rails request/cookie pipeline that overwrites its value with an encrypted blob, breaking auth on the next request. The `Authentication` concern reads/writes the cookie; `ApplicationCable::Connection` reads it for ActionCable.
- `GET /session/test_login` logs in `test@example.com` without credentials. Used by Playwright E2E tests. Gated to non-production at both the route and the controller action — keep it that way.

## Inline Editing (transactions)

- Row click → `row-edit` Stimulus controller (on the `<tbody>`) fetches `/transactions/:id/edit?account_id=N` and inserts the returned `<tr>` after the read-only row.
- Parsing the `<tr>` back into the DOM uses `Range#createContextualFragment` against the `<tbody>`. Don't switch to `template.innerHTML` — `<tr>` outside a table context gets stripped by the parser.
- Edit-row Stimulus controller is `row-edit-form`. `blur` autosave is wrapped in `setTimeout(0)` so `document.activeElement` reflects the new focus before deciding whether to save.

## E2E Tests (Playwright)

- Auth fixture is in `tests/fixtures.ts` (`authedPage`). It hits `/session/test_login` per test.
- Run per-project: `npx playwright test --project=chromium` (and again for firefox). Running both projects with `workers>1` causes the shared dev DB session for `test@example.com` to thrash — tests pass per-project but flake when fully parallel. If/when this matters for CI, switch to per-worker test users or per-project invocations.

## Linting

Uses [standardrb](https://github.com/standardrb/standard) with `standard-rails`. Configured in `.rubocop.yml`. The `bin/rubocop` binstub loads standardrb.

## Git Workflow

- Stacked branches managed with [git-spice](https://abhinav.github.io/git-spice/)
- PRs are squash-merged

## Known Issues

- CI test job uses `postgres` image which lacks pgvector extension. Should use `pgvector/pgvector:pg17` to match local dev.
