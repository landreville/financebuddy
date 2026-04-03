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
- **All data is ledger-scoped**: accounts, categories, payees, transactions all belong to a ledger. Users access ledgers via ledger_memberships.

## Linting

Uses [standardrb](https://github.com/standardrb/standard) with `standard-rails`. Configured in `.rubocop.yml`. The `bin/rubocop` binstub loads standardrb.

## Git Workflow

- Stacked branches managed with [git-spice](https://abhinav.github.io/git-spice/)
- PRs are squash-merged

## Known Issues

- CI test job uses `postgres` image which lacks pgvector extension. Should use `pgvector/pgvector:pg17` to match local dev.
