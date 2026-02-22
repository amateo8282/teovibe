# Technology Stack

**Analysis Date:** 2026-02-22

## Languages

**Primary:**
- Ruby 3.3.10 - Backend application language

**Secondary:**
- JavaScript (ES modules via ImportMap) - Frontend interactivity
- SQL - SQLite full-text search (FTS5) queries
- HTML/ERB - Template rendering

## Runtime

**Environment:**
- Ruby 3.3.10 (specified in `.ruby-version`)

**Package Manager:**
- Bundler 2.5.22 - Ruby gem dependency management
- Lockfile: Present (`Gemfile.lock`)

## Frameworks

**Core:**
- Rails 8.1.2 - Full-stack web framework (ActionPack, ActiveRecord, ActionMailer, ActiveStorage)
- Propshaft 1.3.1 - Modern asset pipeline
- Tailwind CSS 4.4.0 - Utility-first CSS framework via `tailwindcss-rails` gem

**Frontend Interactivity:**
- Hotwire (Turbo Rails 2.0.23, Stimulus Rails 1.3.4) - SPA-like page acceleration and modest JavaScript framework
- ImportMap Rails 2.2.3 - JavaScript module loading without bundling

**Database:**
- SQLite 2.9.0 (>= 2.1) - Primary data store with FTS5 virtual tables for full-text search
- Solid Cache 1.0.10 - Database-backed cache store
- Solid Queue 1.3.1 - Database-backed job queue
- Solid Cable 3.0.12 - Database-backed WebSocket adapter

**Content & Images:**
- ActionText - Rich text editor with Trix support
- Image Processing 1.2 - Image transformation using ImageMagick/Ruby-Vips

**Testing:**
- Capybara 3.40.0 - System/acceptance testing
- Selenium WebDriver 4.40.0 - Browser automation for system tests
- Minitest 6.0.1 - Built-in Rails testing framework

**Development Tools:**
- Bootsnap 1.23.0 - Boot time cache for faster startup
- Web Console 4.2.1 - Interactive debugging via browser
- Letter Opener 1.10.0 - Email preview in development
- Brakeman 8.0.2 - Static security analysis
- Bundler Audit 0.9.3 - Known gem vulnerability scanner
- RuboCop Rails Omakase 1.1.0 - Opinionated Ruby/Rails style enforcement

**Build & Deployment:**
- Kamal 2.10.1 - Docker-based deployment orchestration
- Thruster 0.1.18 - HTTP caching and asset acceleration for Puma
- Docker - Container runtime (Ruby 3.3.10 slim base image)
- Kamal Postgres support - Available but not currently used

## Key Dependencies

**Critical:**
- ActiveRecord - ORM (included in Rails) for database abstraction
- Rails Security Headers - CSRF protection, CSP, SSL enforcement
- bcrypt 3.1.7 - Password hashing (via `has_secure_password`)

**Infrastructure:**
- Puma 7.2.0 - Web server
- Rack 3.2.5 - Web application interface
- Rake 13.3.1 - Task runner
- Bundler 2.5.22 - Dependency management

**Utilities:**
- Pagy 43.2.10 - Pagination (lightweight alternative to Kaminari)
- Meta-Tags 2.22.3 - SEO meta tag management
- Sitemap Generator 6.3.0 - XML sitemap generation
- JBuilder 2.14.1 - JSON rendering
- Nokogiri 1.19.1 - HTML/XML parsing (used by Rails)

**HTTP & Network:**
- Faraday 2.14.1 - HTTP client (as OAuth2 dependency)
- OAuth2 2.0.18 - OAuth2 protocol implementation
- JWT 3.1.2 - JSON Web Token signing/verification

## Configuration

**Environment:**
- Configured via `config/environments/` files (development, test, production)
- Secrets managed via `config/master.key` and `config/credentials.yml.enc`
- Development uses `letter_opener` for email preview
- Production uses Gmail SMTP via credentials

**Build:**
- `config/application.rb` - Application initialization (Rails 8.1 defaults)
- `.ruby-version` - Ruby version constraint
- `Dockerfile` - Multi-stage production build
- `config/deploy.yml` - Kamal deployment configuration
- `.dockerignore` - Docker build exclusions

**Database Configuration:**
- `config/database.yml` - SQLite configuration with three databases in production (primary, cache, queue)
- `db/structure.sql` - Schema definition using SQL (not migrations) for FTS5 support
- Schema format set to `:sql` to preserve SQLite-specific features

**Storage:**
- `config/storage.yml` - Active Storage configuration
- Development/test: Local disk storage at `storage/`
- Production: Local disk storage (mounted Docker volume)
- AWS S3 support commented out but available

**Caching:**
- `config/cache.yml` - Solid Cache configuration (database-backed)
- Production cache database: `storage/production_cache.sqlite3`
- 256MB max size per environment

**Job Queue:**
- `config/queue.yml` - Solid Queue configuration
- Polling-based dispatcher with 1-second interval
- Worker pool: 3 threads per process with configurable concurrency via `JOB_CONCURRENCY` env var
- Production queue database: `storage/production_queue.sqlite3`

**WebSockets:**
- `config/cable.yml` - Action Cable configuration
- Development: Async adapter (same-process only)
- Production: Solid Cable with database polling (0.1s interval, 1-day message retention)

## Platform Requirements

**Development:**
- Ruby 3.3.10
- SQLite 3.8.0+
- Bundler 2.5+
- Node.js compatible environment (for Asset Pipeline and TypeScript)
- ImageMagick or libvips for image processing

**Production:**
- Docker (orchestrated via Kamal)
- Ruby 3.3.10 slim image
- 2GB+ RAM recommended (WEB_CONCURRENCY: 2)
- Persistent storage volume for SQLite files
- SMTP server access (Gmail SMTP configured)
- Environment variables: `RAILS_MASTER_KEY`, optionally `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET`

---

*Stack analysis: 2026-02-22*
