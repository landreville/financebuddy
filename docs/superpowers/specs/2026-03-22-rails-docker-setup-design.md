# FinanceBuddy: Rails 8 Application Setup

## Overview

Set up a Ruby on Rails 8 application with AlpineJS as the frontend interactivity layer, PostgreSQL 17 as the database, and Redis 7 for background jobs/caching. Docker Compose manages Postgres and Redis; Rails runs on the host for fast development iteration.

## Stack

| Layer       | Technology                        | Notes                                      |
|-------------|-----------------------------------|--------------------------------------------|
| Backend     | Ruby 3.3, Rails 8                 | Latest stable                              |
| Database    | PostgreSQL 17                     | Dockerized via `postgres:17-alpine`        |
| Cache/Queue | Redis 7                           | Dockerized via `redis:7-alpine`            |
| JS          | AlpineJS via importmaps           | No Node build step for Rails               |
| CSS         | Bootstrap via `cssbundling-rails` | Rails-managed CSS bundling                 |
| Testing     | Playwright (existing)             | E2E tests, separate Node/Yarn toolchain    |

## 1. Docker Compose

A `docker-compose.yml` at the project root with two services:

### PostgreSQL

- Image: `postgres:17-alpine`
- Port: `5432:5432`
- Named volume: `financebuddy_postgres_data`
- Health check: `pg_isready -U $POSTGRES_USER`
- Environment variables: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` with defaults for local dev

### Redis

- Image: `redis:7-alpine`
- Port: `6379:6379`
- Named volume: `financebuddy_redis_data`
- Health check: `redis-cli ping`

### Environment Configuration

- `.env.example` committed with sensible defaults:
  - `POSTGRES_USER=financebuddy`
  - `POSTGRES_PASSWORD=password`
  - `POSTGRES_DB=financebuddy_development`
  - `REDIS_URL=redis://localhost:6379/0`
- `.env` added to `.gitignore` (developers copy `.env.example` to `.env`)

## 2. Rails Application

Generated with:

```bash
rails new . --database=postgresql --css=bootstrap --skip-docker
```

Key flags:
- `--database=postgresql` — configures `pg` gem and generates `database.yml`
- `--css=bootstrap` — sets up `cssbundling-rails` with Bootstrap
- `--skip-docker` — we provide our own Docker Compose setup
- `.` — generates into the current directory, preserving existing files

### database.yml

Configured to read from environment variables with local dev defaults:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  port: <%= ENV.fetch("DATABASE_PORT", 5432) %>
  username: <%= ENV.fetch("DATABASE_USERNAME", "financebuddy") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "password") %>

development:
  <<: *default
  database: financebuddy_development

test:
  <<: *default
  database: financebuddy_test

production:
  <<: *default
  database: financebuddy_production
  url: <%= ENV["DATABASE_URL"] %>
```

## 3. AlpineJS Integration

Added via importmaps (no Node build step):

```bash
bin/importmap pin alpinejs
```

Initialized in `app/javascript/application.js`:

```javascript
import Alpine from "alpinejs"
window.Alpine = Alpine
Alpine.start()
```

## 4. Existing Files — Preserved

The following files/directories remain untouched:

- `package.json`, `yarn.lock`, `node_modules/` — Playwright tooling only
- `playwright.config.ts`, `tests/` — E2E test infrastructure
- `.github/workflows/playwright.yml` — CI workflow for Playwright

The existing `.gitignore` will be merged with Rails-generated entries. Both Ruby and Playwright patterns coexist.

## 5. Developer Workflow

```bash
# Start Postgres and Redis
docker compose up -d

# First-time database setup
bin/rails db:create db:migrate

# Start Rails server
bin/rails server

# App available at http://localhost:3000

# Run Playwright E2E tests (separate concern)
yarn playwright test
```

## Decisions & Rationale

| Decision                          | Rationale                                                                 |
|-----------------------------------|---------------------------------------------------------------------------|
| Rails on host, services in Docker | Fastest dev loop; no volume mount lag or container rebuild on code change  |
| Importmaps over esbuild/Vite      | AlpineJS is lightweight; no need for a JS build pipeline                  |
| Redis included despite Solid*      | Provides flexibility for Sidekiq, Redis-backed caching, or Action Cable   |
| `--skip-docker`                    | We control the Docker setup; Rails' generated Dockerfile is for prod      |
| Bootstrap via cssbundling-rails    | Quick path to a decent UI; Rails-native integration                       |

## Out of Scope

- Production Dockerfile / deployment configuration (Kamal, etc.)
- CI/CD updates for Rails tests (existing Playwright CI stays as-is)
- Application features (handled by separate product brief)
