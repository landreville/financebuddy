# FinanceBuddy: Rails 8 Application Setup

## Overview

Set up a Ruby on Rails 8 application with AlpineJS as the frontend interactivity layer, PostgreSQL 17 as the database, and Redis 7 for background jobs/caching. Docker Compose manages Postgres and Redis; Rails runs on the host for fast development iteration.

## Stack

| Layer       | Technology                        | Notes                                      |
|-------------|-----------------------------------|--------------------------------------------|
| Backend     | Ruby 3.4, Rails 8                 | Matches installed rbenv Ruby 3.4.4         |
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
- Health check: `pg_isready -U financebuddy`
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
rails new . --database=postgresql --css=bootstrap --javascript=importmap --skip-docker
```

Key flags:
- `--database=postgresql` — configures `pg` gem and generates `database.yml`
- `--css=bootstrap` — sets up `cssbundling-rails` with Bootstrap
- `--javascript=importmap` — explicit importmap selection (Rails 8 default, stated for clarity)
- `--skip-docker` — we provide our own Docker Compose setup
- `.` — generates into the current directory

### Handling file conflicts

`rails new .` will prompt for conflicts with existing files (`.gitignore`, `package.json`). Strategy:

1. Back up `.gitignore` before running the generator
2. Allow Rails to overwrite `.gitignore`, then manually merge the Playwright patterns back in
3. `package.json` will be **extended** (not replaced) by `cssbundling-rails` — it adds Bootstrap/Sass dependencies and CSS build scripts alongside the existing Playwright `devDependencies`. Verify Playwright entries survive after generation.

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

## 4. Existing Files

- `package.json`, `yarn.lock` — **extended** with Bootstrap/CSS build dependencies; existing Playwright `devDependencies` preserved
- `node_modules/` — will grow with new CSS dependencies
- `playwright.config.ts`, `tests/` — untouched
- `.github/workflows/playwright.yml` — untouched
- `.gitignore` — Rails-generated version merged with existing Playwright patterns; uncomment the `# .env` line to ensure `.env` is gitignored

## 5. Developer Workflow

```bash
# Start Postgres and Redis
docker compose up -d

# First-time database setup
bin/rails db:create db:migrate

# Start Rails server + CSS watcher (via Procfile.dev / foreman)
bin/dev

# App available at http://localhost:3000

# Run Playwright E2E tests (separate concern)
yarn playwright test
```

Note: `bin/dev` uses `foreman` to start both the Rails server and the CSS file watcher (`yarn build:css --watch`) simultaneously. Running `bin/rails server` alone will not recompile CSS on changes.

## Decisions & Rationale

| Decision                          | Rationale                                                                 |
|-----------------------------------|---------------------------------------------------------------------------|
| Rails on host, services in Docker | Fastest dev loop; no volume mount lag or container rebuild on code change  |
| Importmaps over esbuild/Vite      | AlpineJS is lightweight; no need for a JS build pipeline                  |
| Redis included despite Solid*      | Available for Sidekiq/caching/Cable later; Rails configs updated when needed |
| `--skip-docker`                    | We control the Docker setup; Rails' generated Dockerfile is for prod      |
| Bootstrap via cssbundling-rails    | Quick path to a decent UI; Rails-native integration                       |

## Out of Scope

- Production Dockerfile / deployment configuration (Kamal, etc.)
- CI/CD updates for Rails tests (existing Playwright CI stays as-is)
- Application features (handled by separate product brief)
