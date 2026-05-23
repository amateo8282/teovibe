# External Integrations

**Analysis Date:** 2026-02-22

## APIs & External Services

**OAuth2 Social Authentication:**
- Google OAuth2 - Social login via Google accounts
  - SDK/Client: `omniauth-google-oauth2` 1.2.1
  - Auth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` environment variables
  - Config: `config/initializers/omniauth.rb`
  - Mock mode: Enabled in development when credentials not present

- Kakao OAuth2 - Social login via Kakao accounts
  - SDK/Client: `omniauth-kakao` 0.0.1
  - Auth: `KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET` environment variables
  - Config: `config/initializers/omniauth.rb`
  - Mock mode: Enabled in development when credentials not present

**Implementation Details:**
- OmniAuth 2.1.4 middleware handles OAuth flow
- CSRF protection via `omniauth-rails_csrf_protection` 2.0.1
- Post-only allowed for OAuth requests (`OmniAuth.config.allowed_request_methods = [:post]`)
- Development mock credentials:
  - Google: uid "mock-google-uid-12345", email "testuser@gmail.com"
  - Kakao: uid "mock-kakao-uid-67890", email "testuser@kakao.com"

## Data Storage

**Databases:**
- SQLite3 2.9.0
  - Primary: `storage/production.sqlite3` (users, posts, comments, etc.)
  - Cache: `storage/production_cache.sqlite3` (Solid Cache store)
  - Queue: `storage/production_queue.sqlite3` (Solid Queue jobs)
  - Cable: `storage/production_cable.sqlite3` (WebSocket messages)
  - Client: Native SQLite3 gem (built-in ActiveRecord adapter)
  - Features: FTS5 virtual tables for full-text search on posts, SQLite-specific features via structure.sql

**File Storage:**
- Local filesystem (development and production)
  - Root: `storage/` directory (production) or `tmp/storage/` (test)
  - Service: Active Storage with local disk service
  - Supports: Image attachments, file uploads via `has_one_attached` / `has_many_attached`
  - AWS S3 support available (commented in `config/storage.yml`) but not currently enabled

**Caching:**
- Solid Cache (database-backed, not Redis)
  - Store type: SQLite database-backed cache via Solid Cache gem 1.0.10
  - Connection: Separate cache database
  - Max size: 256MB per environment
  - Namespace: Prefixed by `Rails.env`

## Authentication & Identity

**Auth Provider:**
- Custom (email/password) with bcrypt hashing
  - Implementation: `has_secure_password` on User model
  - Password hashing: bcrypt 3.1.7
  - Session management: Built-in Rails sessions via database-backed store
  - Token: No API token authentication (session-based only)

**Connected Services:**
- ConnectedService model for OAuth account linking
  - Stores: provider, uid, access_token per user
  - Allows account linking: Multiple OAuth providers to single user account
  - Implementation: `app/models/connected_service.rb`

**Authorization:**
- Role-based (member/admin enum on User)
  - User#admin? method for checks
  - Admin functionality: CMS, user management, inquiry responses
  - Protected via `authenticate_user!` and role checks in controllers

## Monitoring & Observability

**Error Tracking:**
- Not detected - No integration with Sentry, Rollbar, or similar

**Logs:**
- STDOUT logging to Rails logger
  - Format: Tagged logging with request_id
  - Level: Configurable via `RAILS_LOG_LEVEL` env var (default: "info" in production)
  - Health check path excluded from logs: `/up` endpoint

**Security Scanning:**
- Brakeman 8.0.2 - Rails static security analysis (CI/CD)
- Bundler Audit 0.9.3 - Known gem vulnerability scanning (CI/CD)
- RuboCop - Code style/quality via rubocop-rails-omakase 1.1.0

## CI/CD & Deployment

**Hosting:**
- Docker containers orchestrated via Kamal 2.10.1
- GitHub Container Registry (GHCR) for image storage
- Configuration: `config/deploy.yml`
- Server: SSH-based deployment to specified IP(s)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - Triggers: Pull requests and pushes to main branch
  - Jobs:
    - `scan_ruby`: Brakeman (Rails security) + Bundler Audit (gem vulnerabilities)
    - `scan_js`: ImportMap audit (JavaScript dependencies)
    - `lint`: RuboCop style enforcement with caching
    - `test`: MiniTest suite
    - `system-test`: Capybara + Selenium system tests
  - Artifacts: Screenshots from failed system tests

**Deployment Process:**
- Kamal handles Docker image building, registry push, and SSH deployment
- Multi-stage Dockerfile with builder stage for reduced final image size
- Entrypoint: `bin/docker-entrypoint` for database preparation
- Server command: Thruster (HTTP caching) + Rails server

## Environment Configuration

**Required env vars:**
- `RAILS_MASTER_KEY` - Secret key for credentials.yml.enc decryption
- `GOOGLE_CLIENT_ID` - Google OAuth app ID (optional, enables Google OAuth)
- `GOOGLE_CLIENT_SECRET` - Google OAuth app secret
- `KAKAO_CLIENT_ID` - Kakao OAuth app ID (optional, enables Kakao OAuth)
- `KAKAO_CLIENT_SECRET` - Kakao OAuth app secret

**Optional env vars:**
- `RAILS_LOG_LEVEL` - Logging level (default: "info")
- `JOB_CONCURRENCY` - Job queue process count (default: 1)
- `WEB_CONCURRENCY` - Puma worker processes (set to 2 in deploy.yml)
- `SOLID_QUEUE_IN_PUMA` - Run queue in Puma process (set to true in deploy.yml)

**Secrets location:**
- `config/master.key` - Root encryption key for credentials
- `config/credentials.yml.enc` - Encrypted credentials (SMTP, OAuth secrets)
- Development: `config/credentials/development.yml.enc`
- Production: `config/credentials/production.yml.enc`
- Email: SMTP credentials stored under `smtp.user_name` and `smtp.password`

## Email

**SMTP Configuration:**
- Provider: Gmail SMTP
- Host: `smtp.gmail.com` (port 587)
- Authentication: Plain with STARTTLS
- Credentials: Fetched from `Rails.application.credentials.dig(:smtp, :user_name|:password)`
- From address: `noreply@teovibe.com`

**Email Usage:**
- Password reset emails: `PasswordsMailer` (`app/mailers/passwords_mailer.rb`)
- Inquiry responses: `InquiryMailer` (`app/mailers/inquiry_mailer.rb`)
- Base class: `ApplicationMailer` with default from address

**Development:**
- Letter Opener gem opens emails in browser instead of sending
- No actual SMTP sending in development mode

## Webhooks & Callbacks

**Incoming:**
- OmniAuth callback route: `/auth/:provider/callback` - Handled by `Omniauth::SessionsController#create`
- Failure route: `/auth/failure` - Redirects to login with alert

**Outgoing:**
- Not detected - No outgoing webhooks to external services

## Search

**Full-Text Search:**
- SQLite FTS5 (Full-Text Search 5)
- Virtual table: `posts_fts` on posts table
- Indexed fields: title, body, slug
- Schema: Defined in `db/structure.sql` (FTS-specific, requires SQL format)
- Usage: Full-text search on blog posts and tutorials

---

*Integration audit: 2026-02-22*
